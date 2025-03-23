import json
import os
import time
import pickle
import gzip
import base64
import shutil
from typing import Any, Dict, List, Optional, Union, Tuple
from datetime import datetime

class StorageManager:
    """
    Utility for managing persistent storage with expiration and size limits
    """
    
    def __init__(self, storage_dir: str = 'storage', namespace: str = 'sripedia_',
                 options: Optional[Dict[str, Any]] = None):
        """
        Initialize the storage manager
        
        Args:
            storage_dir: Directory path for storing data
            namespace: Namespace prefix for keys
            options: Configuration options
        """
        self.storage_dir = storage_dir
        self.namespace = namespace
        
        # Default options
        self.options = {
            'default_expiration': 86400,  # 24 hours in seconds
            'max_entries': 1000,
            'max_size': 50 * 1024 * 1024,  # 50MB max storage
            'compress': True,
            'index_file': 'storage_index.json'
        }
        
        # Update with user options
        if options:
            self.options.update(options)
        
        # Create storage directory if it doesn't exist
        os.makedirs(self.storage_dir, exist_ok=True)
        
        # Load or initialize index
        self.index = self._load_index()
    
    def set_item(self, key: str, value: Any, expiration: Optional[int] = None) -> bool:
        """
        Store an item
        
        Args:
            key: Key to store the value under
            value: Value to store (any pickle-able object)
            expiration: Expiration time in seconds or None for no expiration
            
        Returns:
            bool: Success status
        """
        full_key = self.namespace + key
        
        # Check storage limits before adding
        if self._is_storage_full():
            self._clean_up()
        
        # Create data object
        data_obj = {
            'value': value,
            'timestamp': int(time.time()),
            'expires_at': int(time.time()) + (expiration or self.options['default_expiration']) if expiration is not None else None
        }
        
        # File path for storage
        file_path = os.path.join(self.storage_dir, f"{full_key}.dat")
        
        try:
            # Serialize and optionally compress
            if self.options['compress']:
                with gzip.open(file_path, 'wb') as f:
                    pickle.dump(data_obj, f, protocol=pickle.HIGHEST_PROTOCOL)
            else:
                with open(file_path, 'wb') as f:
                    pickle.dump(data_obj, f, protocol=pickle.HIGHEST_PROTOCOL)
            
            # Update index
            self.index[full_key] = {
                'created_at': data_obj['timestamp'],
                'expires_at': data_obj['expires_at'],
                'file_path': file_path,
                'size': os.path.getsize(file_path)
            }
            
            self._save_index()
            return True
        except Exception as e:
            print(f"Error saving data: {e}")
            return False
    
    def get_item(self, key: str, default: Any = None) -> Any:
        """
        Retrieve an item
        
        Args:
            key: Key to retrieve
            default: Value to return if key doesn't exist
            
        Returns:
            Retrieved value or default
        """
        full_key = self.namespace + key
        
        # Check if key exists in index
        if full_key not in self.index:
            return default
        
        # Get file path from index
        file_path = self.index[full_key]['file_path']
        
        # Check if file exists
        if not os.path.exists(file_path):
            # Remove from index if file doesn't exist
            del self.index[full_key]
            self._save_index()
            return default
        
        try:
            # Check if expired
            expires_at = self.index[full_key]['expires_at']
            if expires_at and expires_at < int(time.time()):
                self.remove_item(key)
                return default
            
            # Read and deserialize data
            if self.options['compress']:
                with gzip.open(file_path, 'rb') as f:
                    data_obj = pickle.load(f)
            else:
                with open(file_path, 'rb') as f:
                    data_obj = pickle.load(f)
            
            return data_obj['value']
        except Exception as e:
            print(f"Error loading data: {e}")
            return default
    
    def remove_item(self, key: str) -> bool:
        """
        Remove an item
        
        Args:
            key: Key to remove
            
        Returns:
            bool: Success status
        """
        full_key = self.namespace + key
        
        if full_key not in self.index:
            return False
        
        file_path = self.index[full_key]['file_path']
        
        try:
            # Remove file if it exists
            if os.path.exists(file_path):
                os.remove(file_path)
            
            # Remove from index
            del self.index[full_key]
            self._save_index()
            return True
        except Exception as e:
            print(f"Error removing data: {e}")
            return False
    
    def clear(self) -> bool:
        """
        Clear all items in this namespace
        
        Returns:
            bool: Success status
        """
        success = True
        keys_to_remove = []
        
        # Collect keys in namespace
        for full_key in self.index:
            if full_key.startswith(self.namespace):
                keys_to_remove.append(full_key)
        
        # Remove each item
        for full_key in keys_to_remove:
            file_path = self.index[full_key]['file_path']
            try:
                if os.path.exists(file_path):
                    os.remove(file_path)
                del self.index[full_key]
            except Exception as e:
                print(f"Error removing {full_key}: {e}")
                success = False
        
        self._save_index()
        return success
    
    def get_all_keys(self) -> List[str]:
        """
        Get all keys in this namespace
        
        Returns:
            List of keys without namespace prefix
        """
        keys = []
        for full_key in self.index:
            if full_key.startswith(self.namespace):
                keys.append(full_key[len(self.namespace):])
        return keys
    
    def get_stats(self) -> Dict[str, Any]:
        """
        Get storage statistics
        
        Returns:
            Dict with statistics
        """
        total_size = 0
        expired_count = 0
        namespace_count = 0
        current_time = int(time.time())
        
        for full_key, info in self.index.items():
            if full_key.startswith(self.namespace):
                namespace_count += 1
                total_size += info['size']
                if info['expires_at'] and info['expires_at'] < current_time:
                    expired_count += 1
        
        return {
            'total_entries': len(self.index),
            'namespace_entries': namespace_count,
            'expired_entries': expired_count,
            'total_size_bytes': total_size,
            'total_size_mb': round(total_size / (1024 * 1024), 2),
            'storage_dir': self.storage_dir,
            'namespace': self.namespace
        }
    
    def _is_storage_full(self) -> bool:
        """
        Check if storage is full
        
        Returns:
            bool: True if storage limits are exceeded
        """
        # Check entry count
        if len(self.index) >= self.options['max_entries']:
            return True
        
        # Check total size
        total_size = sum(info['size'] for info in self.index.values())
        return total_size >= self.options['max_size']
    
    def _clean_up(self) -> None:
        """Clean up storage by removing expired items or oldest items"""
        # First remove expired items
        expired_removed = self._remove_expired_items()
        
        # If still too many items, remove oldest
        if expired_removed < 1 or self._is_storage_full():
            self._remove_oldest_items()
    
    def _remove_expired_items(self) -> int:
        """
        Remove expired items
        
        Returns:
            int: Number of items removed
        """
        removed_count = 0
        current_time = int(time.time())
        
        keys_to_remove = []
        for full_key, info in self.index.items():
            if info['expires_at'] and info['expires_at'] < current_time:
                keys_to_remove.append(full_key)
        
        for full_key in keys_to_remove:
            file_path = self.index[full_key]['file_path']
            try:
                if os.path.exists(file_path):
                    os.remove(file_path)
                del self.index[full_key]
                removed_count += 1
            except Exception as e:
                print(f"Error removing expired item {full_key}: {e}")
        
        if removed_count > 0:
            self._save_index()
        
        return removed_count
    
    def _remove_oldest_items(self) -> int:
        """
        Remove oldest items until storage is below limits
        
        Returns:
            int: Number of items removed
        """
        # Create list of (key, timestamp) pairs
        items = [(key, info['created_at']) for key, info in self.index.items()]
        
        # Sort by timestamp (oldest first)
        items.sort(key=lambda x: x[1])
        
        removed_count = 0
        # Remove oldest until below limits
        while items and self._is_storage_full():
            oldest_key = items.pop(0)[0]
            file_path = self.index[oldest_key]['file_path']
            
            try:
                if os.path.exists(file_path):
                    os.remove(file_path)
                del self.index[oldest_key]
                removed_count += 1
            except Exception as e:
                print(f"Error removing oldest item {oldest_key}: {e}")
        
        if removed_count > 0:
            self._save_index()
        
        return removed_count
    
    def _load_index(self) -> Dict[str, Dict[str, Any]]:
        """
        Load storage index
        
        Returns:
            Dict: Storage index
        """
        index_path = os.path.join(self.storage_dir, self.options['index_file'])
        
        if os.path.exists(index_path):
            try:
                with open(index_path, 'r') as f:
                    return json.load(f)
            except Exception as e:
                print(f"Error loading index: {e}")
        
        return {}
    
    def _save_index(self) -> bool:
        """
        Save storage index
        
        Returns:
            bool: Success status
        """
        index_path = os.path.join(self.storage_dir, self.options['index_file'])
        
        try:
            # Create temp file
            temp_path = index_path + '.tmp'
            with open(temp_path, 'w') as f:
                json.dump(self.index, f, indent=2)
            
            # Replace original file with temp file
            shutil.move(temp_path, index_path)
            return True
        except Exception as e:
            print(f"Error saving index: {e}")
            return False
    
    def vacuum(self) -> Dict[str, int]:
        """
        Clean up storage and optimize
        
        Returns:
            Dict with cleanup statistics
        """
        stats = {
            'expired_removed': 0,
            'missing_removed': 0,
            'total_removed': 0
        }
        
        # Remove expired items
        stats['expired_removed'] = self._remove_expired_items()
        
        # Remove entries with missing files
        keys_to_remove = []
        for full_key, info in self.index.items():
            if not os.path.exists(info['file_path']):
                keys_to_remove.append(full_key)
        
        for full_key in keys_to_remove:
            del self.index[full_key]
            stats['missing_removed'] += 1
        
        if stats['missing_removed'] > 0:
            self._save_index()
        
        stats['total_removed'] = stats['expired_removed'] + stats['missing_removed']
        return stats


# Example usage
if __name__ == "__main__":
    # Create storage manager
    storage = StorageManager(storage_dir="./storage", namespace="example_")
    
    # Store some data
    storage.set_item("user_1", {"name": "John Doe", "email": "john@example.com"})
    storage.set_item("counter", 42, expiration=3600)  # Expires in 1 hour
    
    # Retrieve data
    user = storage.get_item("user_1")
    counter = storage.get_item("counter")
    
    print(f"User: {user}")
    print(f"Counter: {counter}")
    
    # Get storage stats
    stats = storage.get_stats()
    print(f"Storage stats: {stats}")