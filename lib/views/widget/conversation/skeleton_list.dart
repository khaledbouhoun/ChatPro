part of '../../screens/conversation_screen.dart';

class _SkeletonList extends SliverToBoxAdapter {
  _SkeletonList()
      : super(
          child: Column(
            children: List.generate(
              8,
              (i) => Shimmer.fromColors(
                baseColor: const Color(0xFF111827),
                highlightColor: const Color(0xFF1E2D42),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 14,
                              width: 140,
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(7)),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 11,
                              width: 220,
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
}
