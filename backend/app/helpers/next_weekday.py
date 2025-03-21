from datetime import datetime, timedelta
import warnings

def next_weekday(weekday_number: int) -> datetime:
    warnings.warn("deprecated", DeprecationWarning)
    # Get today's date
    today = datetime.now()
    
    # Calculate how many days to add to get to the next specified weekday
    days_ahead = (weekday_number - today.weekday() + 7) % 7
    
    # Calculate the next weekday date
    next_date = today + timedelta(days=days_ahead)
    
    return next_date
