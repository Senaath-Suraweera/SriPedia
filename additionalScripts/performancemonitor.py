import time
import json
import threading
import logging
import traceback
import uuid
import platform
import sys
import os
import psutil
import requests
from datetime import datetime
from typing import Dict, List, Any, Optional, Callable, Union
from contextlib import contextmanager

class PerformanceMonitor:
    """
    Utility for monitoring application performance in Python applications
    """
    
    def __init__(self, options: Dict[str, Any] = None):
        """
        Initialize the performance monitor
        
        Args:
            options: Configuration options
        """
        default_options = {
            'enabled': True,
            'sample_rate': 0.1,  # 10% sampling
            'max_events': 100,
            'log_to_file': True,
            'log_file': 'performance.log',
            'send_to_server': False,
            'server_endpoint': 'http://localhost:8000/api/performance',
            'include_system_info': True,
            'include_memory_stats': True,
            'auto_flush_seconds': 60
        }
        
        self.options = default_options.copy()
        if options:
            self.options.update(options)
        
        # Initialize event storage
        self.events: List[Dict[str, Any]] = []
        self.timers: Dict[str, Dict[str, Any]] = {}
        
        # Setup logging
        self.logger = logging.getLogger('performance_monitor')
        self.logger.setLevel(logging.INFO)
        
        if self.options['log_to_file']:
            file_handler = logging.FileHandler(self.options['log_file'])
            formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
            file_handler.setFormatter(formatter)
            self.logger.addHandler(file_handler)
        
        # System info cache
        self._system_info: Dict[str, Any] = {}
        
        # Setup auto-flush timer if enabled
        if self.options['enabled'] and self.options['auto_flush_seconds'] > 0:
            self._start_auto_flush()
    
    def _start_auto_flush(self):
        """Start the auto-flush timer thread"""
        def flush_timer_thread():
            while True:
                time.sleep(self.options['auto_flush_seconds'])
                self.flush_events()
        
        thread = threading.Thread(target=flush_timer_thread, daemon=True)
        thread.start()
    
    def get_system_info(self) -> Dict[str, Any]:
        """
        Get detailed system information
        
        Returns:
            Dict containing system information
        """
        if not self._system_info:
            self._system_info = {
                'platform': platform.platform(),
                'python_version': sys.version,
                'processor': platform.processor(),
                'hostname': platform.node(),
                'cpu_count': os.cpu_count(),
                'memory_total': psutil.virtual_memory().total,
                'timezone': datetime.now().astimezone().tzinfo.tzname(None)
            }
        
        # Always update dynamic system info
        dynamic_info = {}
        if self.options['include_memory_stats']:
            memory = psutil.virtual_memory()
            dynamic_info.update({
                'memory_available': memory.available,
                'memory_percent': memory.percent,
                'cpu_percent': psutil.cpu_percent(interval=0.1)
            })
        
        return {**self._system_info, **dynamic_info}
    
    @contextmanager
    def measure_time(self, name: str, additional_data: Dict[str, Any] = None):
        """
        Context manager to measure execution time
        
        Args:
            name: Name of the timer
            additional_data: Additional data to include in the event
            
        Example:
            with perf_monitor.measure_time('db_query', {'query_type': 'select'}):
                # Code to time goes here
                result = db.execute_query()
        """
        timer_id = self.start_timer(name)
        try:
            yield
        finally:
            self.end_timer(timer_id, additional_data or {})
    
    def start_timer(self, name: str) -> str:
        """
        Start a timer for custom performance measurement
        
        Args:
            name: Name of the timer
            
        Returns:
            Timer ID string
        """
        if not self.options['enabled']:
            return ""
            
        timer_id = f"{name}_{uuid.uuid4()}"
        self.timers[timer_id] = {
            'name': name,
            'start_time': time.time(),
            'start_cpu_time': time.process_time()
        }
        return timer_id
    
    def end_timer(self, timer_id: str, additional_data: Dict[str, Any] = None):
        """
        End a timer and record the duration
        
        Args:
            timer_id: ID of the timer to end
            additional_data: Additional data to include in the event
        """
        if not self.options['enabled'] or not timer_id:
            return
            
        timer = self.timers.get(timer_id)
        if not timer:
            return
            
        end_time = time.time()
        end_cpu_time = time.process_time()
        
        wall_time = (end_time - timer['start_time']) * 1000  # Convert to ms
        cpu_time = (end_cpu_time - timer['start_cpu_time']) * 1000  # Convert to ms
        
        data = {
            'name': timer['name'],
            'wall_time_ms': round(wall_time, 2),
            'cpu_time_ms': round(cpu_time, 2)
        }
        
        if additional_data:
            data.update(additional_data)
            
        self.add_event('timer', data)
        del self.timers[timer_id]
    
    def track_function(self, func=None, name=None, additional_data=None):
        """
        Decorator to track function execution time
        
        Args:
            func: Function to decorate
            name: Custom name for the timer (defaults to function name)
            additional_data: Additional data to include
            
        Returns:
            Decorated function
            
        Example:
            @perf_monitor.track_function(name='data_processor', additional_data={'priority': 'high'})
            def process_data(items):
                # ...
        """
        def decorator(f):
            func_name = name or f.__name__
            
            def wrapper(*args, **kwargs):
                timer_id = self.start_timer(func_name)
                try:
                    result = f(*args, **kwargs)
                    return result
                finally:
                    data = additional_data.copy() if additional_data else {}
                    self.end_timer(timer_id, data)
            
            return wrapper
            
        if func is None:
            return decorator
        else:
            return decorator(func)
    
    def track_memory(self, name: str, data: Dict[str, Any] = None):
        """
        Track current memory usage
        
        Args:
            name: Name for this memory snapshot
            data: Additional context data
        """
        if not self.options['enabled']:
            return
            
        process = psutil.Process()
        memory_info = process.memory_info()
        
        memory_data = {
            'name': name,
            'rss_bytes': memory_info.rss,
            'vms_bytes': memory_info.vms,
            'percent': process.memory_percent()
        }
        
        if data:
            memory_data.update(data)
            
        self.add_event('memory', memory_data)
    
    def track_error(self, error: Exception, context: Dict[str, Any] = None):
        """
        Track an exception
        
        Args:
            error: The exception object
            context: Additional context information
        """
        if not self.options['enabled']:
            return
            
        error_data = {
            'type': error.__class__.__name__,
            'message': str(error),
            'traceback': traceback.format_exc()
        }
        
        if context:
            error_data['context'] = context
            
        self.add_event('error', error_data)
        self.flush_events()  # Flush events immediately on error
    
    def track_event(self, event_name: str, event_data: Dict[str, Any] = None):
        """
        Track a custom event
        
        Args:
            event_name: Name of the event
            event_data: Event data
        """
        if not self.options['enabled']:
            return
            
        data = {'event': event_name}
        if event_data:
            data.update(event_data)
            
        self.add_event('custom', data)
    
    def add_event(self, event_type: str, data: Dict[str, Any]):
        """
        Add event to the queue
        
        Args:
            event_type: Event type
            data: Event data
        """
        if not self.options['enabled']:
            return
            
        event = {
            'type': event_type,
            'timestamp': datetime.now().isoformat(),
            'data': data
        }
        
        # Include system info if configured
        if self.options['include_system_info'] and event_type in ('error', 'memory'):
            event['system'] = self.get_system_info()
            
        self.events.append(event)
        
        # Log the event
        self.logger.info(f"Performance event: {event_type} - {json.dumps(data)}")
        
        # Limit queue size
        while len(self.events) > self.options['max_events']:
            self.events.pop(0)
    
    def flush_events(self):
        """Send events to the server or write to log"""
        if not self.options['enabled'] or not self.events:
            return
            
        events_copy = self.events.copy()
        self.events = []
        
        # Log flush
        self.logger.info(f"Flushing {len(events_copy)} performance events")
        
        # Send to server if configured
        if self.options['send_to_server']:
            try:
                requests.post(
                    self.options['server_endpoint'],
                    json={'events': events_copy},
                    timeout=2  # Short timeout to prevent blocking
                )
            except Exception as e:
                self.logger.error(f"Failed to send performance data: {str(e)}")
                # Put events back in queue
                self.events = events_copy + self.events
                # But still respect max size
                while len(self.events) > self.options['max_events']:
                    self.events.pop(0)

# Example usage
if __name__ == "__main__":
    # Create a performance monitor instance
    monitor = PerformanceMonitor({
        'log_file': 'sripedia_performance.log',
        'send_to_server': True,
        'server_endpoint': 'https://sripedia.example.com/api/performance'
    })
    
    # Example: Measure function execution time
    @monitor.track_function
    def expensive_operation(n):
        result = 0
        for i in range(n):
            result += i
        return result
    
    # Example: Using context manager
    with monitor.measure_time('data_processing', {'data_size': 1000}):
        # Simulate data processing
        expensive_operation(1000000)
    
    # Example: Track memory usage
    monitor.track_memory('after_processing')
    
    # Example: Track custom event
    monitor.track_event('user_action', {
        'action': 'search',
        'query': 'Sri Lanka history',
        'results_count': 42
    })
    
    # Example: Track error
    try:
        1/0
    except Exception as e:
        monitor.track_error(e, {'context': 'example operation'})
    
    # Manual flush
    monitor.flush_events()
    