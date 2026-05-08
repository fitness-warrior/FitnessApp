import '../models/chart_model.dart';
 
final chartSelection = [
  Chart(
    name: 'track callories',
    measure: [
      'total',
      'just intake',
      'just cardio',
    ],
  ),
  //these will get their info on if the user has 
  //done at least one thing of the exercise (later)
  Chart(
    name: 'cardio speed',
    measure: [
      'Jump Rope',
      'Running',
    ],
  ),
   Chart(
    name: 'cardio enduance',
    measure: [
      'Jump Rope',
      'Running',
    ],
  ),
   Chart(
    name: 'total weight lifted',
    measure: [
      'Bench Press',
      'Deadlift',
    ],
  ),
   Chart(
    name: 'weight personal bests',
    measure: [
      'Bench Press',
      'Deadlift',
    ],
  ),
];