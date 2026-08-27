import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/localization_service.dart';
import '../widgets/app_button.dart';
import 'login_screen.dart';

/// Onboarding screen introducing AgroSaathi with instant language selection.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'icon': Icons.psychology_outlined,
      'color': AppColors.primary,
      'title': 'AI Crop Recommender',
      'title_hi': 'स्मार्ट फसल अनुशंसा',
      'title_mr': 'स्मार्ट पीक सल्लागार',
      'desc': 'Discover the most profitable and climate-resilient crops for your specific soil type and seasonal conditions.',
      'desc_hi': 'अपनी मिट्टी और मौसम के आधार पर सबसे अधिक लाभदायक फसलें चुनें।',
      'desc_mr': 'आपल्या जमिनीनुसार आणि हंगामानुसार सर्वात फायदेशीर पिकांची माहिती मिळवा.',
    },
    {
      'icon': Icons.bug_report_outlined,
      'color': AppColors.warning,
      'title': 'Plant Disease Detection',
      'title_hi': 'पौधों के रोग की पहचान',
      'title_mr': 'पीक रोग निदान',
      'desc': 'Instantly detect leaf diseases using our deep learning camera scanner with cure and prevention guidelines.',
      'desc_hi': 'पत्ती के फोटो से रोग पहचानें और तुरंत उपचार व रोकथाम के उपाय पाएं।',
      'desc_mr': 'पानांच्या फोटोवरून तत्काळ रोगांचे निदान आणि उपाय योजना जाणून घ्या.',
    },
    {
      'icon': Icons.timeline_outlined,
      'color': AppColors.accent,
      'title': 'Crop Growth Planner',
      'title_hi': 'फसल विकास योजना',
      'title_mr': 'पीक वाढ व व्यवस्थापन',
      'desc': 'Step-by-step guidance for timely irrigation, scheduled fertilizer doses, and harvest countdown reminders.',
      'desc_hi': 'सिंचाई और उर्वरक प्रबंधन के लिए स्वचालित अनुस्मारक और समय सारिणी।',
      'desc_mr': 'पाण्याच्या पाळ्या आणि खत व्यवस्थापनासाठी वेळेवर मिळणारे शेती नियोजन.',
    },
    {
      'icon': Icons.storefront_outlined,
      'color': AppColors.secondary,
      'title': 'Direct Marketplace',
      'title_hi': 'प्रत्यक्ष कृषि बाज़ार',
      'title_mr': 'थेट शेतकरी बाजारपेठ',
      'desc': 'List your harvest and connect with nearby buyers for fair prices with real-time bidding.',
      'desc_hi': 'अपनी उपज को सूचीबद्ध करें और सत्यापित खरीदारों से सर्वोत्तम बोली प्राप्त करें।',
      'desc_mr': 'आपला शेतीमाल थेट खरेदीदारांना विका आणि योग्य बाजारभाव मिळवा.',
    },
  ];

  String _getSlideTitle(Map<String, dynamic> slide) {
    final lang = LocalizationService.currentLocale.value;
    if (lang == 'hi') return slide['title_hi'];
    if (lang == 'mr') return slide['title_mr'];
    return slide['title'];
  }

  String _getSlideDesc(Map<String, dynamic> slide) {
    final lang = LocalizationService.currentLocale.value;
    if (lang == 'hi') return slide['desc_hi'];
    if (lang == 'mr') return slide['desc_mr'];
    return slide['desc'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ValueListenableBuilder<String>(
          valueListenable: LocalizationService.currentLocale,
          builder: (context, currentLang, _) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // Language Selection Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.eco, color: AppColors.primary, size: 24),
                          const SizedBox(width: 6),
                          Text(
                            'AgroSaathi',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: currentLang,
                            items: const [
                              DropdownMenuItem(value: 'en', child: Text('English', style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: 'hi', child: Text('हिन्दी', style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: 'mr', child: Text('मराठी', style: TextStyle(fontSize: 13))),
                            ],
                            onChanged: (val) {
                              if (val != null) LocalizationService.setLocale(val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Carousel
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _slides.length,
                      onPageChanged: (idx) {
                        setState(() => _currentPage = idx);
                      },
                      itemBuilder: (context, index) {
                        final slide = _slides[index];
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                color: (slide['color'] as Color).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                slide['icon'] as IconData,
                                size: 70,
                                color: slide['color'] as Color,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              _getSlideTitle(slide),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _getSlideDesc(slide),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.textSecondary,
                                height: 1.45,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // Indicator Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (idx) {
                      final isActive = idx == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: isActive ? 24 : 8,
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.primary : AppColors.cardBorder,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  AppButton(
                    text: _currentPage == _slides.length - 1 ? 'Get Started' : 'Next',
                    onPressed: () {
                      if (_currentPage == _slides.length - 1) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  if (_currentPage < _slides.length - 1)
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: const Text(
                        'Skip to Login',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  else
                    const SizedBox(height: 48),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
