from datetime import datetime
from sqlalchemy import Column, DateTime


class TimestampMixin(object):
    """
    Provides the :attr:`created_at` and :attr:`updated_at` audit timestamps
    """
    #: Timestamp for when this instance was created in UTC
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    #: Timestamp for when this instance was last updated in UTC
    updated_at = Column(
        DateTime,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
        nullable=False
    )

    created_at._creation_order = 9998
    updated_at._creation_order = 9999
