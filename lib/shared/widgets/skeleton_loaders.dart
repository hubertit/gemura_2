import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';

class SkeletonLoaders {
  static Widget walletCardSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacing16),
        padding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: AppTheme.spacing16,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withOpacity(0.85),
              AppTheme.primaryColor.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with wallet icon and name
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                                        children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacing8),
                        Container(
                          width: 120,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 60,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing16),
            // Balance section
            Container(
              width: 100,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Container(
              width: 150,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            // Bottom row with wallet type and date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 80,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  width: 100,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget walletListSkeleton({int count = 3}) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      itemCount: count,
      itemBuilder: (context, index) => walletCardSkeleton(),
    );
  }

  static Widget homeWalletSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacing8),
        padding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: AppTheme.spacing16,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withOpacity(0.85),
              AppTheme.primaryColor.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                                          children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacing8),
                          Container(
                            width: 100,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 50,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing12),
            // Balance
            Container(
              width: 80,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Container(
              width: 120,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget homeWalletsSkeleton() {
    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: 3,
        controller: PageController(viewportFraction: 0.92),
        itemBuilder: (context, index) => homeWalletSkeleton(),
      ),
    );
  }

  static Widget quickActionsSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16, horizontal: AppTheme.spacing8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (index) => Expanded(
              child: Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  Container(
                    width: 40,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            )),
          ),
        ),
      ),
    );
  }

  static Widget addItemCardSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacing16),
        padding: const EdgeInsets.all(AppTheme.spacing16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
          border: Border.all(
            color: Colors.grey[200]!,
            width: AppTheme.thinBorderWidth,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Container(
                    width: 180,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget generalSkeleton({
    required double width,
    required double height,
    double borderRadius = 4,
  }) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  static Widget fullWalletsTabSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Container(
            width: 80,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          backgroundColor: AppTheme.surfaceColor,
          elevation: 0,
          actions: [
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Quick actions skeleton
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16, horizontal: AppTheme.spacing8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(4, (index) => Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing8),
                        Container(
                          width: 40,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  )),
                ),
              ),
            ),
            // Wallet cards skeleton
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(AppTheme.spacing16),
                itemCount: 4,
                                 itemBuilder: (context, index) => Container(
                   margin: const EdgeInsets.only(bottom: AppTheme.spacing16),
                   padding: const EdgeInsets.symmetric(
                     vertical: 14,
                     horizontal: AppTheme.spacing16,
                   ),
                   decoration: BoxDecoration(
                     borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
                     gradient: LinearGradient(
                       colors: [
                         AppTheme.primaryColor.withOpacity(0.85),
                         AppTheme.primaryColor.withOpacity(0.7),
                       ],
                       begin: Alignment.topLeft,
                       end: Alignment.bottomRight,
                     ),
                     boxShadow: [
                       BoxShadow(
                         color: AppTheme.primaryColor.withOpacity(0.08),
                         blurRadius: 16,
                         offset: const Offset(0, 4),
                       ),
                     ],
                   ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                                                   children: [
                         Container(
                           width: 28,
                           height: 28,
                           decoration: BoxDecoration(
                             color: Colors.white.withOpacity(0.9),
                             borderRadius: BorderRadius.circular(8),
                           ),
                         ),
                         const SizedBox(width: AppTheme.spacing8),
                         Container(
                           width: 120,
                           height: 20,
                           decoration: BoxDecoration(
                             color: Colors.white.withOpacity(0.9),
                             borderRadius: BorderRadius.circular(4),
                           ),
                         ),
                       ],
                     ),
                     Container(
                       width: 60,
                       height: 20,
                       decoration: BoxDecoration(
                         color: Colors.white.withOpacity(0.9),
                         borderRadius: BorderRadius.circular(8),
                       ),
                     ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacing16),
                                             // Balance section
                       Container(
                         width: 100,
                         height: 24,
                         decoration: BoxDecoration(
                           color: Colors.white.withOpacity(0.9),
                           borderRadius: BorderRadius.circular(4),
                         ),
                       ),
                       const SizedBox(height: AppTheme.spacing8),
                       Container(
                         width: 150,
                         height: 16,
                         decoration: BoxDecoration(
                           color: Colors.white.withOpacity(0.9),
                           borderRadius: BorderRadius.circular(4),
                         ),
                       ),
                      const SizedBox(height: AppTheme.spacing16),
                                             // Bottom row
                       Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           Container(
                             width: 80,
                             height: 16,
                             decoration: BoxDecoration(
                               color: Colors.white.withOpacity(0.9),
                               borderRadius: BorderRadius.circular(4),
                             ),
                           ),
                           Container(
                             width: 100,
                             height: 16,
                             decoration: BoxDecoration(
                               color: Colors.white.withOpacity(0.9),
                               borderRadius: BorderRadius.circular(4),
                             ),
                           ),
                         ],
                       ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget fullHomeTabSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Container(
            width: 80,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          backgroundColor: AppTheme.surfaceColor,
          elevation: 0,
          actions: [
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Wallet cards skeleton
              SizedBox(
                height: 200,
                child: PageView.builder(
                  itemCount: 3,
                  controller: PageController(viewportFraction: 0.92),
                                     itemBuilder: (context, index) => Container(
                     margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacing8),
                     padding: const EdgeInsets.symmetric(
                       vertical: 14,
                       horizontal: AppTheme.spacing16,
                     ),
                     decoration: BoxDecoration(
                       borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
                       gradient: LinearGradient(
                         colors: [
                           AppTheme.primaryColor.withOpacity(0.85),
                           AppTheme.primaryColor.withOpacity(0.7),
                         ],
                         begin: Alignment.topLeft,
                         end: Alignment.bottomRight,
                       ),
                       boxShadow: [
                         BoxShadow(
                           color: AppTheme.primaryColor.withOpacity(0.08),
                           blurRadius: 16,
                           offset: const Offset(0, 4),
                         ),
                       ],
                     ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                   children: [
                           Row(
                             children: [
                               Container(
                                 width: 28,
                                 height: 28,
                                 decoration: BoxDecoration(
                                   color: Colors.white.withOpacity(0.9),
                                   borderRadius: BorderRadius.circular(8),
                                 ),
                               ),
                               const SizedBox(width: AppTheme.spacing8),
                               Container(
                                 width: 100,
                                 height: 18,
                                 decoration: BoxDecoration(
                                   color: Colors.white.withOpacity(0.9),
                                   borderRadius: BorderRadius.circular(4),
                                 ),
                               ),
                             ],
                           ),
                           Container(
                             width: 50,
                             height: 18,
                             decoration: BoxDecoration(
                               color: Colors.white.withOpacity(0.9),
                               borderRadius: BorderRadius.circular(8),
                             ),
                           ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacing12),
                                                 Container(
                           width: 80,
                           height: 20,
                           decoration: BoxDecoration(
                             color: Colors.white.withOpacity(0.9),
                             borderRadius: BorderRadius.circular(4),
                           ),
                         ),
                         const SizedBox(height: AppTheme.spacing8),
                         Container(
                           width: 120,
                           height: 14,
                           decoration: BoxDecoration(
                             color: Colors.white.withOpacity(0.9),
                             borderRadius: BorderRadius.circular(4),
                           ),
                         ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing4),
              // Quick actions skeleton
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16, horizontal: AppTheme.spacing8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(4, (index) => Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing8),
                          Container(
                            width: 40,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing24),
              // Stats cards skeleton
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacing8),
                            Container(
                              width: 60,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                    Expanded(
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacing8),
                            Container(
                              width: 60,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
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
}
