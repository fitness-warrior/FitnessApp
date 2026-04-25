# Requirements

## Functional Requirements

### Account & Authentication
- FR 1 - Account Creation: The system shall allow users to create a new account by inputting 
their first and last name, a valid email address and a strong password
- FR 2 - Login from any Device: The system shall allow users to access their account across 
multiple devices using their email and password
- FR 3 - Multi-Device Access: The system shall allow users to access the same account from 
multiple devices
- FR 4 - Account Data Synchronisation: The system shall synchronise user account data across 
all devices

### Fitness Data
- FR 5 - Enter Fitness Information: The system must let users enter basic fitness information 
including weight, activity level, height and diet
- FR 6 - Select Fitness Goal: The system should let users select a personal fitness goal 
including losing weight, gaining muscle or maintaining a healthy lifestyle
- FR 7 - Generate Customised Fitness Plan: The system should generate a clear customized 
fitness plan based on user input and selected goal

### Notifications
- FR 8 - Receive Fitness Related Notifications: The system must allow users to receive 
notifications related to their fitness activities, workout reminders, streak updates and 
meal suggestions
- FR 9 - Control Notification Settings: The system must provide settings that allow users 
to fully control which notifications they receive
- FR 10 - Enable/Disable Notifications and Specific Types: The system shall allow users to 
enable or disable notifications at any time

### Navigation
- FR 11 - Navigation Access: The system shall provide a navigation system that allows users 
to access all main features of the app
- FR 12 - Menu and Button Clarity: The system shall provide well organised menus and clearly 
labelled buttons to support navigation

### Custom Tasks
- FR 13 - Create Custom Fitness Tasks: The system must allow users to create their own custom 
fitness tasks that support their personal goals
- FR 14 - Edit Custom Tasks and Goals: The system shall allow users to edit custom fitness 
tasks and goals at any time
- FR 15 - Record Completed Tasks: The system will record completed tasks
- FR 16 - Use Task Data for Progress, Streaks and Rewards: The system will use completed task 
data to support progress tracking, streak calculation and reward allocation

### Rewards
- FR 17 - Automatic Rewards On Task Completion: The system must automatically reward users 
when they complete a task
- FR 18 - Reward Types: The system shall provide rewards in the form of avatar items, 
accessories, cosmetic upgrades and in-game currency
- FR 19 - Reward Type and Rarity Based On Task Difficulty: The system shall determine the 
type and rarity of the reward based on difficulty of the completed task
- FR 20 - Rewards Added To Inventory Immediately: The system shall add earned rewards to 
the user's inventory and make them available for immediate use
- FR 21 - Prevent Duplicate Rewards Per Task: The system shall ensure that rewards are only 
given once per completed task

### Avatar
- FR 22 - Avatar Creation and Customisation: The system must provide an avatar customisation 
feature that allows users to create and modify a visual character representing themselves
- FR 23 - Equip Cosmetic and Stat-Boosting Items: The system must allow users to equip 
cosmetic and stat-boosting items earned through tasks or minigames

### Progress Tracking
- FR 24 - Store User Fitness Data: The system must store user fitness data including body 
weight, workout performance, calories, steps, lap times and exercise sets
- FR 25 - Generate and Display Progress Line Graph: The system must generate and display a 
line graph that visually shows changes in fitness data over time
- FR 26 - Plot Fitness Data Across Different Dates: The system shall plot user fitness data 
across different dates on the line graph

### Workout Guidance
- FR 27 - Store Workout Guidance Video Sources: The system shall store YouTube links or video 
sources in the database
- FR 28 - Retrieve and Play Tutorial Sources: The system must be able to retrieve and play 
tutorials directly from stored video sources
- FR 29 - Display Workout Guidance When an Exercise is Selected: The system must display the 
workout guidance video when a user searches and selects an exercise

### Minigame
- FR 30 - Provide a Minigame During Rest Time: The system must provide a minigame for the 
user to play during rest time
- FR 31 - Use The User's Customised Avatar in the Minigame: The system shall use the user's 
created and customised avatar within the minigame
- FR 32 - Reward Users After Minigame Completion: The system should reward users with rewards 
from the minigame which should update the user's inventory immediately after completion

### Meal Collection
- FR 33 - Browse and Choose Meals: The system must provide the user with a variety of meals 
to browse and choose from
- FR 34 - Display Meal Nutritional Information: The system shall display nutritional 
information for each meal including calorie and protein content
- FR 35 - Display Nutritional Information: The system shall display nutritional information 
clearly
- FR 36 - Display Ingredients and Preparation Steps: The system must provide the ingredients 
required and the steps to prepare each recipe

### Workout Plans
- FR 37 - Provide Multiple Workout Plans: The system should provide multiple workout plans 
for the user to choose from
- FR 38 - Provide Multiple Difficulty Levels per Plan: The system must make sure that workout 
plans contain multiple difficulties for the user to choose from
- FR 39 - Allow Users to Choose Whether Difficulty Increases Over Time: The system shall 
allow users to choose whether the workout plan increases in difficulty over time

## Non-Functional Requirements

### Performance
- NFR 2 - Response Time: The system will synchronise data across all devices within an 
acceptable timeframe
- NFR 7 - Plan Generation Performance: The system should generate the custom fitness plan 
within a short response time
- NFR 23 - Minigame Responsiveness: The minigame should be responsive and respond to user 
inputs within 200ms

### Reliability
- NFR 3 - Reliability: The system will store user account data in a centralised database 
to ensure reliability and availability
- NFR 6 - Reliability During Data Updates: The system must allow fitness data updates 
without system errors or crashes
- NFR 14 - Reliable Storage for Task Data: The system shall reliably record and store task 
completion data without loss

### Security
- NFR 4 - Secure Data Storage: The system must store all fitness data securely to protect 
user privacy

### Usability
- NFR 10 - UI Consistency and Transitions: The system shall ensure smooth transitions 
between screens and consistent layout across the app
- NFR 11 - Navigation Efficiency: The navigation system shall allow users to reach any main 
feature within a small number of steps
- NFR 13 - Ease of Use for Task Management: The system shall use an easy to use interface 
for creating, editing and completing tasks
- NFR 24 - Meal Information Clarity and Readability: The information about the meal should 
be clearly highlighted and easy to understand