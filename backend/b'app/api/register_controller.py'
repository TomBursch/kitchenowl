from app.config import app
import app.controller as api

# Register Endpoints
app.register_blueprint(
    api.health, url_prefix='/api/health/8M4F88S8ooi4sMbLBfkkV7ctWwgibW6V')
app.register_blueprint(api.auth,       url_prefix='/api/auth')
app.register_blueprint(api.expense,    url_prefix='/api/expense')
app.register_blueprint(api.export,     url_prefix='/api/export')
app.register_blueprint(api.importBP,   url_prefix='/api/import')
app.register_blueprint(api.item,       url_prefix='/api/item')
app.register_blueprint(api.onboarding, url_prefix='/api/onboarding')
app.register_blueprint(api.planner,    url_prefix='/api/planner')
app.register_blueprint(api.recipe,     url_prefix='/api/recipe')
app.register_blueprint(api.settings,   url_prefix='/api/settings')
app.register_blueprint(api.shoppinglist, url_prefix='/api/shoppinglist')
app.register_blueprint(api.tag,        url_prefix='/api/tag')
app.register_blueprint(api.user,       url_prefix='/api/user')
app.register_blueprint(api.upload,     url_prefix='/api/upload')
