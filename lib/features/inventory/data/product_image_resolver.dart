/// Intelligent resolver that maps product names / keywords to curated,
/// high-resolution Unsplash product images with exact dimensioning.
class ProductImageResolver {
  ProductImageResolver._();

  static const Map<String, String> _knownKeywords = {
    'oil': 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&w=160&q=80',
    'mustard': 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&w=160&q=80',
    'rice': 'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=160&q=80',
    'basmati': 'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=160&q=80',
    'noodle': 'https://images.unsplash.com/photo-1612927601601-6638404737ce?auto=format&fit=crop&w=160&q=80',
    'wai wai': 'https://images.unsplash.com/photo-1612927601601-6638404737ce?auto=format&fit=crop&w=160&q=80',
    'tea': 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?auto=format&fit=crop&w=160&q=80',
    'tokla': 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?auto=format&fit=crop&w=160&q=80',
    'sugar': 'https://images.unsplash.com/photo-1581441363689-1f3c3c414635?auto=format&fit=crop&w=160&q=80',
    'soap': 'https://images.unsplash.com/photo-1600857544200-b2f666a9a2ec?auto=format&fit=crop&w=160&q=80',
    'lifebuoy': 'https://images.unsplash.com/photo-1600857544200-b2f666a9a2ec?auto=format&fit=crop&w=160&q=80',
    'biscuit': 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?auto=format&fit=crop&w=160&q=80',
    'cookie': 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?auto=format&fit=crop&w=160&q=80',
    'milk': 'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=160&q=80',
    'bread': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=160&q=80',
    'egg': 'https://images.unsplash.com/photo-1516467508483-a7212febe31a?auto=format&fit=crop&w=160&q=80',
    'flour': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=160&q=80',
    'coffee': 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=160&q=80',
    'spice': 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?auto=format&fit=crop&w=160&q=80',
    'masala': 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?auto=format&fit=crop&w=160&q=80',
    'salt': 'https://images.unsplash.com/photo-1518110925495-5fe2fda0442c?auto=format&fit=crop&w=160&q=80',
    'dal': 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?auto=format&fit=crop&w=160&q=80',
    'lentil': 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?auto=format&fit=crop&w=160&q=80',
  };

  /// Returns an image URL if the product matches any known retail category,
  /// or null if none matches.
  static String? resolveImageUrl(String productName) {
    final lower = productName.toLowerCase();
    for (final entry in _knownKeywords.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }
}
