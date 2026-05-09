from typing import Any, Self, List, TYPE_CHECKING, cast
from app import db
from app.helpers import DbModelAuthorizeMixin
from sqlalchemy.orm import Mapped

Model = db.Model
if TYPE_CHECKING:
    from app.models import Household, History, Item, Shoppinglist, User
    from app.helpers.db_model_base import DbModelBase

    Model = DbModelBase


class Shoppinglist(Model, DbModelAuthorizeMixin):
    __tablename__ = "shoppinglist"

    id: Mapped[int] = db.Column(db.Integer, primary_key=True)
    name: Mapped[str] = db.Column(db.String(128))

    household_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("household.id"), nullable=False, index=True
    )

    household: Mapped["Household"] = cast(
        Mapped["Household"],
        db.relationship(
            "Household",
            uselist=False,
        ),
    )
    items: Mapped[List["ShoppinglistItems"]] = cast(
        Mapped[List["ShoppinglistItems"]],
        db.relationship(
            "ShoppinglistItems",
            cascade="all, delete-orphan",
        ),
    )

    history: Mapped[List["History"]] = cast(
        Mapped[List["History"]],
        db.relationship(
            "History",
            back_populates="shoppinglist",
            cascade="all, delete-orphan",
        ),
    )

    @classmethod
    def getDefault(cls, household_id: int) -> Self:
        return cast(
            Self,
            cls.query.filter(cls.household_id == household_id).order_by(cls.id).first(),
        )

    def isDefault(self) -> bool:
        return self.id == self.getDefault(self.household_id).id

    @classmethod
    def get_items_sorted(cls, household_id: int, shoppinglist_id: int) -> list:
        """
        Gibt Einkaufslisten-Items basierend auf Haushalt-Sortiereinstellungen zurück
        """
        from app.models import Item, Category, Household
        
        household = Household.find_by_id(household_id)
        if not household:
            raise Exception("Household not found")
        
        query = ShoppinglistItems.query.filter(
            ShoppinglistItems.shoppinglist_id == shoppinglist_id
        ).join(ShoppinglistItems.item)
        
        # Sortierung anwenden basierend auf Household-Einstellungen
        sort_type = household.shopping_list_sort_type
        sort_order = household.shopping_list_sort_order
        
        if sort_type == 1:  # BY_CATEGORY
            query = query.join(Item.category, isouter=True).order_by(
                Category.ordering.asc() if sort_order == 0 else Category.ordering.desc(),
                Item.name.asc() if sort_order == 0 else Item.name.desc()
            )
        elif sort_type == 2:  # BY_FREQUENCY
            query = query.order_by(
                Item.support.desc() if sort_order == 0 else Item.support.asc(),
                Item.name.asc()
            )
        elif sort_type == 3:  # CUSTOM (nach manueller Ordnung)
            query = query.order_by(
                Item.ordering.asc() if sort_order == 0 else Item.ordering.desc()
            )
        else:  # BY_NAME (default)
            query = query.order_by(
                Item.name.asc() if sort_order == 0 else Item.name.desc()
            )
        
        return query.all()

    @classmethod
    def all_from_household_sorted(cls, household_id: int) -> list:
        """Gibt alle Einkaufslisten eines Haushalts in der Reihenfolge aus view_ordering zurück"""
        from app.models import Household
        
        household = Household.find_by_id(household_id)
        if not household:
            return []
        
        all_lists = cls.query.filter(cls.household_id == household_id).all()
        
        # Sortiere nach view_ordering
        if household.view_ordering:
            sorted_ids = [int(x) for x in household.view_ordering if x.isdigit()]
            id_to_list = {sl.id: sl for sl in all_lists}
            
            # Zuerst die in view_ordering geordneten Listen
            result = [id_to_list[id] for id in sorted_ids if id in id_to_list]
            
            # Dann die nicht geordneten (neu hinzugefügte)
            result += [sl for sl in all_lists if sl.id not in sorted_ids]
            
            return result
        
        return all_lists


class ShoppinglistItems(Model):
    __tablename__ = "shoppinglist_items"

    shoppinglist_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("shoppinglist.id"), primary_key=True
    )
    item_id: Mapped[int] = db.Column(
        db.Integer, db.ForeignKey("item.id"), primary_key=True
    )
    description: Mapped[str] = db.Column(db.String)
    created_by: Mapped[int | None] = db.Column(
        db.Integer, db.ForeignKey("user.id"), nullable=True
    )

    item: Mapped["Item"] = cast(
        Mapped["Item"],
        db.relationship(
            "Item",
            back_populates="shoppinglists",
        ),
    )
    shoppinglist: Mapped["Shoppinglist"] = cast(
        Mapped["Shoppinglist"],
        db.relationship(
            "Shoppinglist",
            back_populates="items",
        ),
    )
    created_by_user: Mapped["User"] = cast(
        Mapped["User"],
        db.relationship(
            "User",
            foreign_keys=[created_by],
            uselist=False,
        ),
    )

    def obj_to_item_dict(self) -> dict[str, Any]:
        res = self.item.obj_to_dict()
        res["description"] = getattr(self, "description")
        res["created_at"] = getattr(self, "created_at")
        res["updated_at"] = getattr(self, "updated_at")
        res["created_by"] = getattr(self, "created_by")
        return res

    @classmethod
    def find_by_ids(cls, shoppinglist_id: int, item_id: int) -> Self | None:
        return cls.query.filter(
            cls.shoppinglist_id == shoppinglist_id, cls.item_id == item_id
        ).first()
