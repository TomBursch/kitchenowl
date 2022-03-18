from datetime import datetime

from flask_sqlalchemy import BaseQuery
from sqlalchemy import Column, DateTime


class Query(BaseQuery):
    """
    Extends flask.ext.sqlalchemy.BaseQuery to add additional helper methods.
    """

    def notempty(self) -> bool:
        """
        Returns the equivalent of ``bool(query.count())`` but using an
        efficient SQL EXISTS function, so the database stops counting
        after the first result is found.
        """
        return self.session.query(self.exists()).first()[0]

    def isempty(self) -> bool:
        """
        Returns the equivalent of ``not bool(query.count())`` but
        using an efficient SQL EXISTS function, so the database stops
        counting after the first result is found.
        """
        return not self.session.query(self.exists()).first()[0]


class TimestampMixin(object):
    """
    Provides the :attr:`created_at` and :attr:`updated_at` audit timestamps
    """
    query_class = Query

    #: Timestamp for when this instance was created, in UTC
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    #: Timestamp for when this instance was last updated (via the app), in UTC
    updated_at = Column(
        DateTime,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
        nullable=False
    )

    created_at._creation_order = 9998
    updated_at._creation_order = 9999
