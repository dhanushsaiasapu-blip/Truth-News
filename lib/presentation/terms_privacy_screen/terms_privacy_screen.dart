import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

class TermsPrivacyScreen extends StatefulWidget {
  final bool showPrivacy;

  const TermsPrivacyScreen({super.key, this.showPrivacy = false});

  @override
  State<TermsPrivacyScreen> createState() => _TermsPrivacyScreenState();
}

class _TermsPrivacyScreenState extends State<TermsPrivacyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.showPrivacy ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppTheme.headlineText,
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Legal',
          style: GoogleFonts.manrope(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.headlineText,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.mutedText,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 2.5,
          tabs: const [
            Tab(text: 'Terms of Service'),
            Tab(text: 'Privacy Policy'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_TermsOfServiceContent(), _PrivacyPolicyContent()],
      ),
    );
  }
}

class _TermsOfServiceContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LegalHeader(
            title: 'Terms of Service',
            lastUpdated: 'Last updated: September 13, 2026',
          ),
          const SizedBox(height: 24),
          _LegalSection(
            title: '1. Acceptance of Terms',
            body:
                'By accessing or using the Truth app ("App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, please do not use the App. These Terms apply to all visitors, users, and others who access or use the App.',
          ),
          _LegalSection(
            title: '2. Description of Service',
            body:
                'Truth is a news aggregation application that presents stories from multiple media outlets in a single, swipeable feed. The App aggregates publicly available news content and provides AI-generated summaries and political lean estimates for informational purposes only. We do not create original news content.',
          ),
          _LegalSection(
            title: '3. User Accounts',
            body:
                'The App does not require accounts, sign-up, passwords, or authentication. You can use the news feed and local bookmark features without creating an account.',
          ),
          _LegalSection(
            title: '4. AI-Generated Content Disclaimer',
            body:
                'If the configured backend uses AI, it may generate clearly labelled summaries or analysis from retrieved articles. Any such processing is performed by the backend; provider credentials are never embedded in the mobile app. The App does not use AI to invent current events or source metadata.',
          ),
          _LegalSection(
            title: '5. Third-Party Content',
            body:
                'The App displays content from third-party news sources. We do not endorse, control, or take responsibility for the content published by these outlets. Links to original articles are provided for convenience; accessing third-party sites is subject to those sites\' own terms and policies. We are not responsible for any content, advertising, products, or other materials on or available from third-party sites.',
          ),
          _LegalSection(
            title: '6. Intellectual Property',
            body:
                'The Truth app, including its design, logo, and original features, is owned by Truth and protected by applicable intellectual property laws. You may not copy, modify, distribute, sell, or lease any part of our services or included software, nor may you reverse engineer or attempt to extract the source code of that software.',
          ),
          _LegalSection(
            title: '7. User Conduct',
            body:
                'You agree not to use the App to: (a) violate any applicable laws or regulations; (b) transmit any harmful, offensive, or disruptive content; (c) attempt to gain unauthorized access to any portion of the App or its related systems; (d) use automated tools to scrape or collect data from the App without our express written permission; or (e) interfere with the proper functioning of the App.',
          ),
          _LegalSection(
            title: '8. Bookmarks and Preferences',
            body:
                'Features such as bookmarking stories and saving topic preferences are provided for your personal, non-commercial use. We reserve the right to modify or discontinue these features at any time without notice.',
          ),
          _LegalSection(
            title: '9. Limitation of Liability',
            body:
                'To the fullest extent permitted by law, Truth and its affiliates, officers, employees, agents, and licensors shall not be liable for any indirect, incidental, special, consequential, or punitive damages, including loss of profits, data, or goodwill, arising out of or in connection with your use of the App or these Terms.',
          ),
          _LegalSection(
            title: '10. Disclaimer of Warranties',
            body:
                'The App is provided on an "as is" and "as available" basis without warranties of any kind, either express or implied, including but not limited to implied warranties of merchantability, fitness for a particular purpose, or non-infringement.',
          ),
          _LegalSection(
            title: '11. Changes to Terms',
            body:
                'We reserve the right to modify these Terms at any time. We will notify users of material changes by updating the "Last updated" date at the top of this page. Your continued use of the App after any changes constitutes your acceptance of the new Terms.',
          ),
          _LegalSection(
            title: '12. Governing Law',
            body:
                'These Terms shall be governed by and construed in accordance with the laws of the jurisdiction in which Truth operates, without regard to its conflict of law provisions.',
          ),
          _LegalSection(
            title: '13. Contact Us',
            body:
                'If you have any questions about these Terms, please contact us at truthscrollablenews@gmail.com.',
          ),
        ],
      ),
    );
  }
}

class _PrivacyPolicyContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LegalHeader(
            title: 'Privacy Policy',
            lastUpdated: 'Last updated: September 13, 2026',
          ),
          const SizedBox(height: 24),
          _LegalSection(
            title: '1. Introduction',
            body:
                'Truth ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use the Truth app. Please read this policy carefully. If you disagree with its terms, please discontinue use of the App.',
          ),
          _LegalSection(
            title: '2. Information We Collect',
            body:
                'The App does not require or collect account credentials. Local features such as bookmarks, ratings, and feedback preferences may be stored on the device. Network requests needed to retrieve news are sent to the configured news backend.',
          ),
          _LegalSection(
            title: '3. How We Use Your Information',
            body:
                'We use local preferences to provide the requested app features. We do not use account authentication or password-reset services.',
          ),
          _LegalSection(
            title: '4. AI Processing',
            body:
                'If the configured backend uses AI, it may generate clearly labelled summaries or analysis from retrieved articles. The mobile app does not send provider credentials to the device and does not use AI to invent current news, sources, URLs, dates, quotes, statistics, or events.',
          ),
          _LegalSection(
            title: '5. Information Sharing',
            body:
                'We do not sell, trade, or rent your personal information to third parties. We may share information with:\n\n• Service Providers: Third-party vendors who assist in operating the App (e.g., cloud hosting, analytics), bound by confidentiality agreements.\n\n• Legal Requirements: If required by law, court order, or governmental authority.\n\n• Business Transfers: In connection with a merger, acquisition, or sale of assets, your information may be transferred as a business asset.',
          ),
          _LegalSection(
            title: '6. Data Retention',
            body:
                'The App stores bookmarks and selected local preferences on the device until you remove them or clear the App data. The App does not maintain user accounts or account records.',
          ),
          _LegalSection(
            title: '7. Security',
            body:
                'We implement industry-standard security measures to protect your information, including encryption in transit (TLS) and at rest. However, no method of transmission over the internet or electronic storage is 100% secure. We cannot guarantee absolute security of your data.',
          ),
          _LegalSection(
            title: '8. Your Rights',
            body:
                'Depending on your location, you may have the following rights regarding your personal data:\n\n• Access: Request a copy of the personal data we hold about you.\n• Correction: Request correction of inaccurate data.\n• Deletion: Request deletion of your personal data.\n• Portability: Request a machine-readable copy of your data.\n• Objection: Object to certain types of processing.\n\nTo exercise these rights, contact us at truthscrollablenews@gmail.com.',
          ),
          _LegalSection(
            title: '9. Children\'s Privacy',
            body:
                'The App is not directed to children under the age of 13. We do not knowingly collect personal information from children under 13. If we become aware that we have collected personal information from a child under 13, we will take steps to delete such information.',
          ),
          _LegalSection(
            title: '10. Third-Party Links',
            body:
                'The App contains links to third-party news articles and websites. We are not responsible for the privacy practices of these third parties. We encourage you to review the privacy policies of any third-party sites you visit.',
          ),
          _LegalSection(
            title: '11. Changes to This Policy',
            body:
                'We may update this Privacy Policy from time to time. We will notify you of any changes by updating the "Last updated" date. Your continued use of the App after changes are posted constitutes your acceptance of the updated policy.',
          ),
          _LegalSection(
            title: '12. Contact Us',
            body:
                'If you have questions or concerns about this Privacy Policy, please contact us at:\n\nEmail: truthscrollablenews@gmail.com\nAddress: Truth News App, Legal Department',
          ),
        ],
      ),
    );
  }
}

class _LegalHeader extends StatelessWidget {
  final String title;
  final String lastUpdated;

  const _LegalHeader({required this.title, required this.lastUpdated});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.manrope(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.headlineText,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          lastUpdated,
          style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.mutedText),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primary.withAlpha(50)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Please read this document carefully before using the Truth app.',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppTheme.primary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegalSection extends StatelessWidget {
  final String title;
  final String body;

  const _LegalSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.headlineText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: AppTheme.bodyText,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}
