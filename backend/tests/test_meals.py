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

@pytest.mark.asyncio
async def test_tc043_save_meal_plan(client, mock_conn):
    """FR33 - Browse and Choose Meals: Save meal plan for a date"""
    token = create_access_token(data={"sub": "1"})
    headers = {"Authorization": f"Bearer {token}"}
    
    mock_conn.fetchval.return_value = None # No existing plan
    
    payload = {
        "plan_date": "2024-05-20",
        "plan": {
            "breakfast": {"name": "Chicken Salad", "recipe_id": 1},
            "lunch": {"name": "Beef Tacos", "recipe_id": 2},
            "dinner": {"name": "Chicken Salad", "recipe_id": 1}
        }
    }
    
    response = await client.post("/api/meals", json=payload, headers=headers)
    
    assert response.status_code == 200
    assert response.json()["success"] is True

@pytest.mark.asyncio
async def test_tc044_update_meal_plan(client, mock_conn):
    """FR33 - Browse and Choose Meals: Update existing meal plan"""
    token = create_access_token(data={"sub": "1"})
    headers = {"Authorization": f"Bearer {token}"}
    
    mock_conn.fetchval.return_value = 500 # Existing plan ID
    
    payload = {
        "plan_date": "2024-05-20",
        "plan": {
            "breakfast": {"name": "Updated Salad", "recipe_id": 1},
            "lunch": {"name": "Beef Tacos", "recipe_id": 2},
            "dinner": {"name": "Chicken Salad", "recipe_id": 1}
        }
    }
    
    response = await client.post("/api/meals", json=payload, headers=headers)
    
    assert response.status_code == 200
    assert response.json()["success"] is True

@pytest.mark.asyncio
async def test_tc045_view_nutritional_info(client, mock_conn):
    """FR34 - Display Nutritional: View meal nutritional info"""
    mock_conn.fetchrow.return_value = {
        "recipe_id": 1, 
        "recipe_meal_name": "Chicken Salad", 
        "recipe_ingredients": "Chicken, Lettuce",
        "recipe_allergy_info": "None",
        "recipe_calories": 450.5,
        "recipe_diet_type": "Keto",
        "recipe_instructions": "Mix everything",
        "recipe_image_url": ""
    }
    
    response = await client.get("/api/recipes/1")
    
    assert response.status_code == 200
    assert response.json()["recipe_calories"] == 450.5

@pytest.mark.asyncio
async def test_tc046_missing_nutritional_data(client, mock_conn):
    """FR34 - Display Nutritional: Meal with missing nutritional data"""
    mock_conn.fetchrow.return_value = {
        "recipe_id": 1, 
        "recipe_meal_name": "Mysterious Soup", 
        "recipe_ingredients": "Water, Magic",
        "recipe_allergy_info": "Unknown",
        "recipe_calories": None,
        "recipe_diet_type": "None",
        "recipe_instructions": "Boil water",
        "recipe_image_url": ""
    }
    
    response = await client.get("/api/recipes/1")
    
    assert response.status_code == 200
    # Should default to 0.0 gracefully
    assert response.json()["recipe_calories"] == 0.0

@pytest.mark.asyncio
async def test_tc047_allergen_info_displayed(client, mock_conn):
    """FR35 - Display Nutritional Information: Allergen information displayed"""
    mock_conn.fetchrow.return_value = {
        "recipe_id": 2, 
        "recipe_meal_name": "Beef Tacos", 
        "recipe_ingredients": "Beef, Tortilla",
        "recipe_allergy_info": "Gluten, Dairy",
        "recipe_calories": 600,
        "recipe_diet_type": "Standard",
        "recipe_instructions": "Assemble",
        "recipe_image_url": ""
    }
    
    response = await client.get("/api/recipes/2")
    
    assert response.status_code == 200
    assert "Gluten" in response.json()["recipe_allergy_info"]

@pytest.mark.asyncio
async def test_tc048_view_recipe(client, mock_conn):
    """FR36 - Display Ingredients and Steps: View recipe for a meal"""
    mock_conn.fetchrow.return_value = {
        "recipe_id": 1, 
        "recipe_meal_name": "Chicken Salad", 
        "recipe_ingredients": "Chicken, Lettuce, Olive Oil",
        "recipe_instructions": "1. Chop chicken. 2. Toss with lettuce. 3. Drizzle oil.",
        "recipe_allergy_info": "None",
        "recipe_calories": 450,
        "recipe_diet_type": "Keto",
        "recipe_image_url": ""
    }
    
    response = await client.get("/api/recipes/1")
    
    assert response.status_code == 200
    assert "Chop chicken" in response.json()["recipe_instructions"]
    assert "Lettuce" in response.json()["recipe_ingredients"]

@pytest.mark.asyncio
async def test_tc049_save_meal_plan_unauthorized(client):
    """FR36 - Display Ingredients and Steps: Save meal plan without being logged in"""
    payload = {"plan_date": "2024-05-20", "plan": {}}
    response = await client.post("/api/meals", json=payload)
    
    assert response.status_code == 401
    assert response.json()["detail"] == "Missing authorization header"
