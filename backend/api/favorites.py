"""
Favorites management for images.
Stores starred/favorited images in a simple JSON file.
"""
import json
import os
from pathlib import Path
from django.conf import settings

FAVORITES_FILE = os.path.join(settings.BASE_DIR, 'favorites.json')


def load_favorites():
    """Load favorites from JSON file."""
    if not os.path.exists(FAVORITES_FILE):
        return []
    
    try:
        with open(FAVORITES_FILE, 'r') as f:
            return json.load(f)
    except Exception:
        return []


def save_favorites(favorites):
    """Save favorites to JSON file."""
    try:
        with open(FAVORITES_FILE, 'w') as f:
            json.dump(favorites, f, indent=2)
        return True
    except Exception:
        return False


def is_favorite(category, filename):
    """Check if an image is favorited."""
    favorites = load_favorites()
    key = f"{category}/{filename}"
    return key in favorites


def toggle_favorite(category, filename):
    """Toggle favorite status of an image."""
    favorites = load_favorites()
    key = f"{category}/{filename}"
    
    if key in favorites:
        favorites.remove(key)
        action = 'removed'
    else:
        favorites.append(key)
        action = 'added'
    
    save_favorites(favorites)
    return action


def get_favorites(category=None):
    """Get all favorites, optionally filtered by category."""
    favorites = load_favorites()
    
    if category:
        return [f for f in favorites if f.startswith(f"{category}/")]
    
    return favorites
