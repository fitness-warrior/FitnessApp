import 'package:flutter/material.dart';

class ResponsiveFooter extends StatelessWidget {
  const ResponsiveFooter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          const Row(
            children: [
              Icon(Icons.fitness_center, size: 32, color: Colors.black),
              SizedBox(width: 8),
              Text('Fitness App',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          // Menu columns
          const SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FooterColumn(
                  title: 'FEATURES',
                  items: [
                    'Workout Planner',
                    'Meal Planner',
                    'Games',
                    'Form & Questionnaires',
                    'Guidance',
                  ],
                ),
                _FooterColumn(
                  title: 'LEARN',
                  items: ['Exercises', 'Contact Support'],
                ),
                _FooterColumn(
                  title: 'PROGRAMS',
                  items: ['Affiliate Program', 'HSA/FSA'],
                ),
                _FooterColumn(
                  title: 'EVALUATE',
                  items: ['How We Compare', 'Case Study', 'Pricing'],
                ),
                _FooterColumn(
                  title: 'EVERFIT IN ACTION',
                  items: ['Free Trial', 'Contact Sales', 'Sign In'],
                ),
                _FooterColumn(
                  title: 'COMPANY',
                  items: ['Fitness Intelligence', 'Careers'],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Newsletter
          const Text('Subscribe to our Newsletter',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'ENTER YOUR EMAIL',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const CircleAvatar(
                backgroundColor: Colors.black,
                child: Icon(Icons.arrow_forward, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Social icons
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(icon: const Icon(Icons.facebook), onPressed: () {}),
              IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: () {}), // Instagram
              IconButton(
                  icon: const Icon(Icons.play_circle_fill),
                  onPressed: () {}), // YouTube
              IconButton(
                  icon: const Icon(Icons.business),
                  onPressed: () {}), // LinkedIn
            ],
          ),
        ],
      ),
    );
  }
}

class _FooterColumn extends StatelessWidget {
  final String title;
  final List<String> items;
  const _FooterColumn({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(item, style: const TextStyle(fontSize: 15)),
              )),
        ],
      ),
    );
  }
}
