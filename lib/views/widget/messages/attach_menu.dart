part of '../../screens/chat_screen.dart';

class _AttachMenu extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final VoidCallback onFile;

  const _AttachMenu(
      {required this.onClose,
      required this.onGallery,
      required this.onCamera,
      required this.onFile});

  @override
  Widget build(BuildContext context) {
    final items = [
      (LucideIcons.image, 'Gallery', const Color(0xFF7C3AED), onGallery),
      (LucideIcons.camera, 'Camera', const Color(0xFF0891B2), onCamera),
      (LucideIcons.file, 'Document', const Color(0xFF059669), onFile),
      (
        LucideIcons.mapPin,
        'Location',
        const Color(0xFFDC2626),
        () => onClose()
      ),
      (LucideIcons.music, 'Audio', const Color(0xFFD97706), () => onClose()),
      (
        LucideIcons.contact2,
        'Contact',
        const Color(0xFF2563EB),
        () => onClose()
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: AppTheme.bg,
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: items
            .asMap()
            .entries
            .map(
              (e) => _AttachItem(
                  icon: e.value.$1,
                  label: e.value.$2,
                  color: e.value.$3,
                  index: e.key,
                  onTap: e.value.$4),
            )
            .toList(),
      ),
    );
  }
}
