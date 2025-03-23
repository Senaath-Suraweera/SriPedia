from datetime import datetime, timedelta
import calendar
import pytz
import locale
from typing import Union, Optional, Dict, Any, Tuple

class DateFormatter:
    """
    Utility for formatting dates and times consistently across the application
    """
    
    def __init__(self, timezone: str = 'Asia/Colombo', locale_str: str = 'en_US'):
        """
        Initialize the date formatter
        
        Args:
            timezone: Default timezone (e.g., 'Asia/Colombo')
            locale_str: Locale string (e.g., 'en_US')
        """
        self.timezone = pytz.timezone(timezone)
        
        # Set locale for month names, etc.
        try:
            locale.setlocale(locale.LC_TIME, locale_str)
        except locale.Error:
            # Fall back to default if locale not available
            pass
    
    def format(self, date: Union[datetime, str, int, float], 
              format_str: str = '%Y-%m-%d', to_timezone: Optional[str] = None) -> str:
        """
        Format a date according to the specified format
        
        Args:
            date: Date to format (datetime, timestamp, or string)
            format_str: strftime format string
            to_timezone: Target timezone or None for default
            
        Returns:
            str: Formatted date string
        """
        dt = self._parse_date(date)
        if not dt:
            return "Invalid date"
        
        # Convert to specified timezone
        if to_timezone:
            target_tz = pytz.timezone(to_timezone)
            dt = dt.astimezone(target_tz)
        elif not dt.tzinfo:
            # Localize naive datetime
            dt = self.timezone.localize(dt)
        
        return dt.strftime(format_str)
    
    def format_sri_lankan(self, date: Union[datetime, str, int, float], 
                         style: str = 'medium') -> str:
        """
        Format a date in Sri Lankan style
        
        Args:
            date: Date to format
            style: Formatting style ('short', 'medium', 'long', 'full')
            
        Returns:
            str: Formatted date string
        """
        dt = self._parse_date(date)
        if not dt:
            return "Invalid date"
        
        # Localize if needed
        if not dt.tzinfo:
            dt = self.timezone.localize(dt)
        
        # Convert to Sri Lankan timezone
        sl_tz = pytz.timezone('Asia/Colombo')
        dt = dt.astimezone(sl_tz)
        
        # Format based on style
        if style == 'short':
            return dt.strftime('%d/%m/%Y')
        elif style == 'medium':
            return dt.strftime('%d %b %Y')
        elif style == 'long':
            return dt.strftime('%d %B %Y')
        elif style == 'full':
            return dt.strftime('%A, %d %B %Y')
        else:
            return dt.strftime('%d %b %Y')
    
    def time_ago(self, date: Union[datetime, str, int, float]) -> str:
        """
        Format a date as a relative time string (e.g., "2 hours ago")
        
        Args:
            date: Date to format
            
        Returns:
            str: Relative time string
        """
        dt = self._parse_date(date)
        if not dt:
            return "Invalid date"
        
        # Ensure datetime is timezone aware
        if not dt.tzinfo:
            dt = self.timezone.localize(dt)
        
        now = datetime.now(dt.tzinfo)
        diff = now - dt
        
        seconds = diff.total_seconds()
        
        if seconds < 0:
            return self._future_time(-seconds)
        
        # Define thresholds
        minute = 60
        hour = minute * 60
        day = hour * 24
        week = day * 7
        month = day * 30
        year = day * 365
        
        if seconds < minute:
            return "just now" if seconds < 10 else f"{int(seconds)} seconds ago"
        elif seconds < hour:
            minutes = int(seconds / minute)
            return f"{minutes} minute ago" if minutes == 1 else f"{minutes} minutes ago"
        elif seconds < day:
            hours = int(seconds / hour)
            return f"{hours} hour ago" if hours == 1 else f"{hours} hours ago"
        elif seconds < week:
            days = int(seconds / day)
            return f"{days} day ago" if days == 1 else f"{days} days ago"
        elif seconds < month:
            weeks = int(seconds / week)
            return f"{weeks} week ago" if weeks == 1 else f"{weeks} weeks ago"
        elif seconds < year:
            months = int(seconds / month)
            return f"{months} month ago" if months == 1 else f"{months} months ago"
        else:
            years = int(seconds / year)
            return f"{years} year ago" if years == 1 else f"{years} years ago"
    
    def _future_time(self, seconds: float) -> str:
        """Format future time"""
        # Define thresholds
        minute = 60
        hour = minute * 60
        day = hour * 24
        week = day * 7
        month = day * 30
        year = day * 365
        
        if seconds < minute:
            return "in a few seconds"
        elif seconds < hour:
            minutes = int(seconds / minute)
            return f"in {minutes} minute" if minutes == 1 else f"in {minutes} minutes"
        elif seconds < day:
            hours = int(seconds / hour)
            return f"in {hours} hour" if hours == 1 else f"in {hours} hours"
        elif seconds < week:
            days = int(seconds / day)
            return f"in {days} day" if days == 1 else f"in {days} days"
        elif seconds < month:
            weeks = int(seconds / week)
            return f"in {weeks} week" if weeks == 1 else f"in {weeks} weeks"
        elif seconds < year:
            months = int(seconds / month)
            return f"in {months} month" if months == 1 else f"in {months} months"
        else:
            years = int(seconds / year)
            return f"in {years} year" if years == 1 else f"in {years} years"
    
    def format_duration(self, duration_seconds: Union[int, float, timedelta]) -> str:
        """
        Format a duration in a human-readable format
        
        Args:
            duration_seconds: Duration in seconds or a timedelta object
            
        Returns:
            str: Formatted duration string
        """
        if isinstance(duration_seconds, timedelta):
            seconds = duration_seconds.total_seconds()
        else:
            seconds = float(duration_seconds)
        
        if seconds < 0:
            return "Invalid duration"
        
        minutes, seconds = divmod(int(seconds), 60)
        hours, minutes = divmod(minutes, 60)
        days, hours = divmod(hours, 24)
        
        parts = []
        
        if days > 0:
            parts.append(f"{days} day{'s' if days != 1 else ''}")
        if hours > 0:
            parts.append(f"{hours} hour{'s' if hours != 1 else ''}")
        if minutes > 0:
            parts.append(f"{minutes} minute{'s' if minutes != 1 else ''}")
        if seconds > 0 or not parts:
            parts.append(f"{seconds} second{'s' if seconds != 1 else ''}")
        
        return ', '.join(parts)
    
    def duration_between(self, start_date: Union[datetime, str, int, float],
                        end_date: Union[datetime, str, int, float],
                        unit: str = 'seconds') -> float:
        """
        Calculate the duration between two dates
        
        Args:
            start_date: Start date
            end_date: End date
            unit: Unit to return ('seconds', 'minutes', 'hours', 'days')
            
        Returns:
            float: Duration in specified unit
        """
        start_dt = self._parse_date(start_date)
        end_dt = self._parse_date(end_date)
        
        if not start_dt or not end_dt:
            return float('nan')
        
        # Ensure datetimes are timezone aware
        if not start_dt.tzinfo:
            start_dt = self.timezone.localize(start_dt)
        if not end_dt.tzinfo:
            end_dt = self.timezone.localize(end_dt)
        
        diff_seconds = (end_dt - start_dt).total_seconds()
        
        if unit == 'seconds':
            return diff_seconds
        elif unit == 'minutes':
            return diff_seconds / 60
        elif unit == 'hours':
            return diff_seconds / 3600
        elif unit == 'days':
            return diff_seconds / 86400
        else:
            return diff_seconds
    
    def get_month_calendar(self, year: int, month: int, 
                         format_str: str = '%Y-%m-%d') -> Dict[str, Any]:
        """
        Get calendar information for a specific month
        
        Args:
            year: Calendar year
            month: Calendar month (1-12)
            format_str: Date format string for the calendar days
            
        Returns:
            Dict with calendar information
        """
        cal = calendar.monthcalendar(year, month)
        month_name = calendar.month_name[month]
        
        # Format days with dates
        formatted_calendar = []
        for week in cal:
            formatted_week = []
            for day in week:
                if day == 0:
                    formatted_week.append(None)
                else:
                    date_obj = datetime(year, month, day)
                    formatted_week.append({
                        'day': day,
                        'date': date_obj.strftime(format_str),
                        'is_weekend': date_obj.weekday() >= 5
                    })
            formatted_calendar.append(formatted_week)
        
        return {
            'year': year,
            'month': month,
            'month_name': month_name,
            'calendar': formatted_calendar,
            'weekdays': list(calendar.day_name),
            'weeks': len(formatted_calendar)
        }
    
    def _parse_date(self, date: Union[datetime, str, int, float]) -> Optional[datetime]:
        """
        Parse different date formats into a datetime object
        
        Args:
            date: Date to parse (datetime, timestamp, or string)
            
        Returns:
            datetime or None if invalid
        """
        if isinstance(date, datetime):
            return date
        
        try:
            if isinstance(date, (int, float)):
                # Assume Unix timestamp
                return datetime.fromtimestamp(date)
            
            if isinstance(date, str):
                # Try common formats
                for fmt in ['%Y-%m-%d', '%Y-%m-%d %H:%M:%S', '%d/%m/%Y', '%m/%d/%Y']:
                    try:
                        return datetime.strptime(date, fmt)
                    except ValueError:
                        continue
                    
                # Try ISO format
                return datetime.fromisoformat(date.replace('Z', '+00:00'))
        except Exception:
            pass
        
        return None


# Example usage
if __name__ == "__main__":
    # Create formatter
    formatter = DateFormatter()
    
    # Current date
    now = datetime.now()
    
    # Format examples
    print(f"ISO format: {formatter.format(now, '%Y-%m-%d')}")
    print(f"Sri Lankan format: {formatter.format_sri_lankan(now, 'full')}")
    
    # Time ago
    past_date = now - timedelta(hours=3)
    print(f"Time ago: {formatter.time_ago(past_date)}")
    
    # Duration
    print(f"Duration: {formatter.format_duration(10800)}")  # 3 hours in seconds