import re
from typing import Dict, Any, List, Union, Callable, Optional, Tuple


class FormValidator:
    """
    A utility class for validating form data in Python applications
    """
    
    def __init__(self):
        """Initialize the form validator"""
        self.errors: Dict[str, List[str]] = {}
        
    def validate(self, data: Dict[str, Any], rules: Dict[str, Dict[str, Any]]) -> bool:
        """
        Validate form data against a set of rules
        
        Args:
            data: Dictionary of form field values
            rules: Dictionary of validation rules for each field
            
        Returns:
            bool: True if validation passes, False otherwise
        """
        self.errors = {}
        
        for field_name, field_rules in rules.items():
            # Skip validation if field isn't required and is empty
            if not field_rules.get('required', False) and (field_name not in data or data[field_name] == ''):
                continue
                
            # Check each rule for the field
            for rule_name, rule_value in field_rules.items():
                # Skip metadata fields
                if rule_name in ['label', 'error_messages']:
                    continue
                
                # Get field value, use empty string if field is missing
                field_value = data.get(field_name, '')
                
                # Validate against rule
                if not self._validate_rule(field_name, field_value, rule_name, rule_value, data, field_rules):
                    break  # Stop checking other rules once one fails
        
        return len(self.errors) == 0
    
    def _validate_rule(self, field_name: str, field_value: Any, rule_name: str, 
                      rule_value: Any, all_data: Dict[str, Any], 
                      field_rules: Dict[str, Any]) -> bool:
        """
        Validate a single rule for a field
        
        Args:
            field_name: Name of the field being validated
            field_value: Value of the field being validated
            rule_name: Name of the rule to validate
            rule_value: Value/parameter for the rule
            all_data: All form data
            field_rules: All rules for the current field
            
        Returns:
            bool: True if validation passes, False otherwise
        """
        # Get custom error messages if provided
        error_messages = field_rules.get('error_messages', {})
        field_label = field_rules.get('label', field_name)
        
        # Define validation logic for each rule type
        if rule_name == 'required' and rule_value:
            if field_value is None or str(field_value).strip() == '':
                self._add_error(field_name, error_messages.get('required', f"{field_label} is required"))
                return False
                
        elif rule_name == 'min_length' and isinstance(field_value, str):
            if len(field_value) < rule_value:
                self._add_error(field_name, error_messages.get('min_length', 
                               f"{field_label} must be at least {rule_value} characters long"))
                return False
                
        elif rule_name == 'max_length' and isinstance(field_value, str):
            if len(field_value) > rule_value:
                self._add_error(field_name, error_messages.get('max_length',
                               f"{field_label} cannot be longer than {rule_value} characters"))
                return False
                
        elif rule_name == 'min' and (isinstance(field_value, (int, float)) or 
                                  (isinstance(field_value, str) and field_value.isdigit())):
            numeric_value = float(field_value) if isinstance(field_value, str) else field_value
            if numeric_value < rule_value:
                self._add_error(field_name, error_messages.get('min',
                               f"{field_label} must be at least {rule_value}"))
                return False
                
        elif rule_name == 'max' and (isinstance(field_value, (int, float)) or 
                                  (isinstance(field_value, str) and field_value.isdigit())):
            numeric_value = float(field_value) if isinstance(field_value, str) else field_value
            if numeric_value > rule_value:
                self._add_error(field_name, error_messages.get('max',
                               f"{field_label} cannot be greater than {rule_value}"))
                return False
                
        elif rule_name == 'email' and rule_value:
            email_pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
            if not re.match(email_pattern, str(field_value)):
                self._add_error(field_name, error_messages.get('email',
                               f"{field_label} must be a valid email address"))
                return False
                
        elif rule_name == 'pattern':
            if not re.match(rule_value, str(field_value)):
                self._add_error(field_name, error_messages.get('pattern',
                               f"{field_label} has an invalid format"))
                return False
                
        elif rule_name == 'in_list':
            if field_value not in rule_value:
                valid_options = ', '.join(str(x) for x in rule_value)
                self._add_error(field_name, error_messages.get('in_list',
                               f"{field_label} must be one of: {valid_options}"))
                return False
                
        elif rule_name == 'equals_field':
            other_field_value = all_data.get(rule_value, '')
            if field_value != other_field_value:
                other_field_label = rules.get(rule_value, {}).get('label', rule_value)
                self._add_error(field_name, error_messages.get('equals_field',
                               f"{field_label} must match {other_field_label}"))
                return False
                
        elif rule_name == 'custom_validator' and callable(rule_value):
            # Custom validator should return (is_valid, error_message)
            is_valid, error_message = rule_value(field_value, all_data)
            if not is_valid:
                self._add_error(field_name, error_message)
                return False
        
        return True
    
    def _add_error(self, field_name: str, error_message: str) -> None:
        """
        Add an error message for a field
        
        Args:
            field_name: Name of the field
            error_message: Error message to add
        """
        if field_name not in self.errors:
            self.errors[field_name] = []
        self.errors[field_name].append(error_message)
    
    def get_errors(self) -> Dict[str, List[str]]:
        """
        Get all validation errors
        
        Returns:
            Dict: Dictionary of field names and their error messages
        """
        return self.errors
    
    def get_first_errors(self) -> Dict[str, str]:
        """
        Get only the first error for each field
        
        Returns:
            Dict: Dictionary of field names and their first error message
        """
        return {field: errors[0] for field, errors in self.errors.items()}


# Example usage
if __name__ == "__main__":
    # Create validator
    validator = FormValidator()
    
    # Define validation rules
    rules = {
        'username': {
            'label': 'Username',
            'required': True,
            'min_length': 3,
            'max_length': 20,
            'pattern': r'^[a-zA-Z0-9_]+$',
            'error_messages': {
                'pattern': 'Username can only contain letters, numbers, and underscores'
            }
        },
        'email': {
            'label': 'Email Address',
            'required': True,
            'email': True
        },
        'password': {
            'label': 'Password',
            'required': True,
            'min_length': 8,
            'custom_validator': lambda value, data: (
                bool(re.search(r'[A-Z]', value) and re.search(r'[0-9]', value)),
                'Password must contain at least one uppercase letter and one number'
            )
        },
        'confirm_password': {
            'label': 'Confirm Password',
            'required': True,
            'equals_field': 'password'
        },
        'age': {
            'label': 'Age',
            'required': True,
            'min': 18,
            'max': 120
        }
    }
    
    # Sample form data
    form_data = {
        'username': 'john_doe',
        'email': 'invalid-email',
        'password': 'password123',
        'confirm_password': 'password',
        'age': '17'
    }
    
    # Validate the form
    is_valid = validator.validate(form_data, rules)
    
    print(f"Form is valid: {is_valid}")
    if not is_valid:
        print("Validation errors:")
        for field, errors in validator.get_errors().items():
            print(f"  {field}: {', '.join(errors)}")