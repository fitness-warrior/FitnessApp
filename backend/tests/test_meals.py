import pytest
from auth import create_access_token
from unittest.mock import AsyncMock

@pytest.mark.asyncio
async def test_tc042_browse_meals(client, mock_conn):
    """FR33 - Browse and Choose Meals: Browse meal collection"""
    token = create_access_token(data={"sub": "1"})
    headers = {"Authorization": f"Bearer {token}"}
    
    mock_conn.fetch.return_value = [
        {
            "recipe_id": 1, 
            "recipe_meal_name": "Chicken Salad", 
            "recipe_ingredients": "Chicken, Lettuce",
            "recipe_allergy_info": "None",
            "recipe_calories": 450,
            "recipe_diet_type": "Keto",
            "recipe_instructions": "Mix everything",
            "recipe_image_url": ""
        },
        {
            "recipe_id": 2, 
            "recipe_meal_name": "Beef Tacos", 
            "recipe_ingredients": "Beef, Tortilla",
            "recipe_allergy_info": "Gluten",
            "recipe_calories": 600,
            "recipe_diet_type": "Standard",
            "recipe_instructions": "Cook beef, assemble",
            "recipe_image_url": ""
        }
    ]
    
    response = await client.get("/api/recipes", headers=headers)
    
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 2
    assert data[0]["recipe_meal_name"] == "Chicken Salad"
