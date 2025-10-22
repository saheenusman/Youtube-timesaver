class MockData {
  static const String videoTitle = 'How to Build a Flutter App in 2025';
  static const String videoDuration = '15:32';
  static const String thumbnailUrl =
      'https://via.placeholder.com/1280x720.png?text=Video+Thumbnail';

  static const List<Map<String, String>> highlights = [
    {
      'timestamp': '02:35',
      'title': 'Project Setup',
      'description': 'Creating a new Flutter project with modern structure.',
      'agentName': 'teacher',
    },
    {
      'timestamp': '07:10',
      'title': 'State Management',
      'description': 'Choosing the right approach for scalability in 2025.',
      'agentName': 'analyst',
    },
    {
      'timestamp': '12:48',
      'title': 'Deployment Tips',
      'description': 'CI/CD and store submission best practices.',
      'agentName': 'explorer',
    },
  ];

  static const Map<String, String> agentStatuses = {
    'teacher': 'Summarizing key concepts...',
    'analyst': 'Extracting metrics...',
    'explorer': 'Finding related resources...',
  };
}
