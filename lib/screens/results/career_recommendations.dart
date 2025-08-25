import 'package:flutter/material.dart';
import '../../models/user_profile_match.dart';
import '../../services/api_service.dart';

class JobRecommendationsScreen extends StatefulWidget {
  final int userTestId;

  const JobRecommendationsScreen({super.key, required this.userTestId});

  @override
  State<JobRecommendationsScreen> createState() =>
      _JobRecommendationsScreenState();
}

class _JobRecommendationsScreenState extends State<JobRecommendationsScreen> {
  UserProfileMatchResponse? _profileMatch;
  bool _isLoading = true;
  String? _errorMessage;
  final Map<int, bool> _expandedCards = {}; // Track which cards are expanded
  int?
      _selectedJobIndex; // Track which job is selected for skills/knowledge display

  @override
  void initState() {
    super.initState();
    _fetchProfileMatch();
  }

  Future<void> _fetchProfileMatch() async {
    try {
      print('STARTED: Fetching profile match...');
      final result = await ApiService.getUserProfileMatch(
        userTestId: widget.userTestId,
      );

      if (result == null) {
        print('FAILED: API returned NULL result');
        setState(() {
          _errorMessage = "Failed to fetch profile match.";
          _isLoading = false;
        });
      } else {
        print('SUCCESS: API call completed!');
        print('Total jobs received: ${result.topMatches.length}');

        // Check each job for skills and knowledge
        for (var i = 0; i < result.topMatches.length; i++) {
          final job = result.topMatches[i];
          print('--- Job ${i + 1} ---');
          print('Title: ${job.jobTitle}');
          print('Index: ${job.jobIndex}');
          print('Skills count: ${job.requiredSkills.length}');
          print('Skills: ${job.requiredSkills}');
          print('Knowledge count: ${job.requiredKnowledge.length}');
          print('Knowledge: ${job.requiredKnowledge}');
          print('');
        }

        setState(() {
          _profileMatch = result;
          _isLoading = false;
          // Set first job as selected by default
          if (_profileMatch!.topMatches.isNotEmpty) {
            _selectedJobIndex = _profileMatch!.topMatches[0].jobIndex;
            _expandedCards[_selectedJobIndex!] = true;
            print('Selected first job by default: Index $_selectedJobIndex');
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Toggle card expansion and selection state
  void _selectCareer(int jobIndex) {
    setState(() {
      // If clicking the already selected career, just toggle expansion
      if (_selectedJobIndex == jobIndex) {
        _expandedCards[jobIndex] = !(_expandedCards[jobIndex] ?? false);
      } else {
        // Select new career and expand it
        _selectedJobIndex = jobIndex;
        _expandedCards[jobIndex] = true;
      }
    });
  }

  // Helper function to format the profile text with better structure
  List<Widget> _formatProfileText(String text) {
    final List<Widget> widgets = [];
    final lines = text.split(';');

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // Check if it's a heading
      if (line.toLowerCase().contains('user profile:') ||
          line.toLowerCase().contains('top job matches:')) {
        widgets.add(
          Text(
            line,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        );
        widgets.add(const SizedBox(height: 8));
      }
      // Check if it's a subheading
      else if (line.contains(':')) {
        final parts = line.split(':');
        widgets.add(
          RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                TextSpan(
                  text: '${parts[0]}:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: parts.length > 1 ? parts[1] : ''),
              ],
            ),
          ),
        );
        widgets.add(const SizedBox(height: 4));
      }
      // Regular bullet point
      else {
        widgets.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• '),
              Expanded(
                child: Text(
                  line,
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),
        );
        widgets.add(const SizedBox(height: 4));
      }
    }

    return widgets;
  }

  Widget _buildJobCard(JobMatch job) {
    final bool isExpanded = _expandedCards[job.jobIndex] ?? false;
    final bool isSelected = _selectedJobIndex == job.jobIndex;

    return Card(
      elevation: isSelected ? 4 : 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
            : BorderSide.none,
      ),
      color: isSelected ? Colors.blue[50] : null,
      child: InkWell(
        onTap: () => _selectCareer(job.jobIndex),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      job.jobTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color:
                            isSelected ? Theme.of(context).primaryColor : null,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(
                      "${job.similarityPercentage.toStringAsFixed(2)}% Match",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: _getMatchColor(job.similarityPercentage),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Short preview of job description
              if (!isExpanded) _buildShortJobPreview(job.jobDescription),

              // Full job description when expanded
              if (isExpanded) ...[
                const SizedBox(height: 12),
                ..._buildFullJobDescription(job.jobDescription),
              ],

              // Expand/collapse indicator
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      isSelected ? "Selected" : "Tap to select",
                      style: TextStyle(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey,
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build skills card for the SELECTED career
  Widget _buildSkillsCard(JobMatch job) {
    print('TRYING to build skills card for: ${job.jobTitle}');
    print('Skills available: ${job.requiredSkills}');
    if (job.requiredSkills.isEmpty) {
      print('SKILLS CARD: No skills to display');
      return const SizedBox.shrink();
    }
    print('SKILLS CARD: Building with ${job.requiredSkills.length} skills');

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.build, size: 20, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  "Key Skills Required",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: job.requiredSkills.map((skill) {
                return Chip(
                  label: Text(
                    skill,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Colors.blue[50],
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // Build knowledge card for the SELECTED career
  Widget _buildKnowledgeCard(JobMatch job) {
    print('TRYING to build knowledge card for: ${job.jobTitle}');
    print('Knowledge available: ${job.requiredKnowledge}');
    if (job.requiredKnowledge.isEmpty) {
      print('KNOWLEDGE CARD: No knowledge to display');
      return const SizedBox.shrink();
    }
    print(
        'KNOWLEDGE CARD: Building with ${job.requiredKnowledge.length} items');

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.school, size: 20, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  "Key Knowledge Required",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: job.requiredKnowledge.map((knowledge) {
                return Chip(
                  label: Text(
                    knowledge,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Colors.green[50],
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // Build short preview of job description
  Widget _buildShortJobPreview(String description) {
    // Extract first sentence or first 120 characters
    String previewText = description;

    // Try to find the first sentence ending
    final firstPeriod = description.indexOf('.');
    if (firstPeriod != -1 && firstPeriod < 120) {
      previewText = description.substring(0, firstPeriod + 1);
    } else {
      // Fallback: first 120 characters with ellipsis
      previewText = description.length > 120
          ? '${description.substring(0, 120)}...'
          : description;
    }

    return Text(
      previewText,
      style: const TextStyle(fontSize: 14, color: Colors.grey),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  // Build full job description with formatting
  List<Widget> _buildFullJobDescription(String description) {
    final List<Widget> widgets = [];

    widgets.add(
      const Text(
        "Responsibilities:",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
    widgets.add(const SizedBox(height: 8));

    widgets.addAll(_formatJobDescription(description));

    return widgets;
  }

  // Helper to format job description
  List<Widget> _formatJobDescription(String description) {
    final List<Widget> widgets = [];
    final lines = description.split('\n');

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // Check if it's a bullet point
      if (line.startsWith('- ') || line.startsWith('• ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• '),
                Expanded(
                  child: Text(
                    line.substring(2).trim(),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      // Regular paragraph
      else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              line,
            ),
          ),
        );
      }
    }

    return widgets;
  }

  // Helper to get color based on match percentage
  Color _getMatchColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.blue;
    if (percentage >= 40) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Career Recommendations"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Section
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "Profile Summary",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:
                              _formatProfileText(_profileMatch!.profileText),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Career Paths Recommendations Section
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "Recommended Career Paths",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._profileMatch!.topMatches
                          .map((job) => _buildJobCard(job))
                          .toList(),

                      // Show skills and knowledge ONLY for the selected career
                      if (_selectedJobIndex != null) ...[
                        // Find the selected job
                        for (final job in _profileMatch!.topMatches)
                          if (job.jobIndex == _selectedJobIndex) ...[
                            _buildSkillsCard(job),
                            _buildKnowledgeCard(job),
                          ],
                      ],

                      // Proceed Button
                      const SizedBox(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // Navigate to Skill Gap Analysis
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Proceed to Skill Gap Analysis",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }
}
