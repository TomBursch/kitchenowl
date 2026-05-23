from app.helpers import validate_args, authorize_household
from flask import jsonify, Blueprint
from app.errors import NotFoundRequest
from flask_jwt_extended import jwt_required
from app.models import Category
from .schemas import AddCategory, DeleteCategory, UpdateCategory

category = Blueprint("category", __name__)
categoryHousehold = Blueprint("category", __name__)


@categoryHousehold.route("", methods=["GET"])
@jwt_required()
@authorize_household()
def getAllCategories(household_id):
    return jsonify([e.obj_to_dict() for e in Category.all_by_ordering(household_id)])


@category.route("/<int:id>", methods=["GET"])
@jwt_required()
def getCategory(id):
    category = Category.find_by_id(id)
    if not category:
        raise NotFoundRequest()
    category.checkAuthorized()
    return jsonify(category.obj_to_dict())


@categoryHousehold.route("", methods=["POST"])
@jwt_required()
@authorize_household()
@validate_args(AddCategory)
def addCategory(args: AddCategory, household_id):
    category = Category()
    category.name = args.name
    category.household_id = household_id
    category.save()
    return jsonify(category.obj_to_dict())


@category.route("/<int:id>", methods=["POST", "PATCH"])
@jwt_required()
@validate_args(UpdateCategory)
def updateCategory(args: UpdateCategory, id):
    category = Category.find_by_id(id)
    if not category:
        raise NotFoundRequest()
    category.checkAuthorized()

    if args.name is not None:
        category.name = args.name
    if args.ordering is not None and category.ordering != args.ordering:
        category.reorder(args.ordering)
    category.save()

    if args.merge_category_id is not None and args.merge_category_id != id:
        mergeCategory = Category.find_by_id(args.merge_category_id)
        if mergeCategory:
            category.merge(mergeCategory)

    return jsonify(category.obj_to_dict())


@category.route("/<int:id>", methods=["DELETE"])
@jwt_required()
def deleteCategoryById(id):
    category = Category.find_by_id(id)
    if not category:
        raise NotFoundRequest()
    category.checkAuthorized()

    category.delete()
    return jsonify({"msg": "DONE"})


@categoryHousehold.route("", methods=["DELETE"])
@jwt_required()
@authorize_household()
@validate_args(DeleteCategory)
def deleteCategoryByName(args: DeleteCategory, household_id):
    if args.name is not None:
        category = Category.find_by_name(args.name, household_id)
        if category:
            category.delete()
            return jsonify({"msg": "DONE"})
    raise NotFoundRequest()
