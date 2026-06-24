import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/location_search_service.dart';

/// Search bar dengan Places autocomplete.
class LocationSearchBar extends StatefulWidget {
  final String apiKey;
  final void Function(String name, LatLng position) onPlaceSelected;

  const LocationSearchBar({
    super.key,
    required this.apiKey,
    required this.onPlaceSelected,
  });

  @override
  State<LocationSearchBar> createState() => _LocationSearchBarState();
}

class _LocationSearchBarState extends State<LocationSearchBar> {
  final _controller = TextEditingController();
  final _searchService = LocationSearchService(apiKey: '');
  List<Map<String, dynamic>> _results = [];
  Timer? _debounce;
  bool _isSearching = false;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.length < 3) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  Future<void> _search(String query) async {
    setState(() => _isSearching = true);
    // Buat service instance dengan API key dari widget
    final service = LocationSearchService(apiKey: widget.apiKey);
    final results = await service.searchPlaces(query);
    if (mounted) {
      setState(() {
        _results = results;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Cari lokasi...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _results = []);
                      },
                    )
                  : null,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onChanged: _onSearchChanged,
          ),
        ),

        // Hasil pencarian
        if (_results.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 250),
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final place = _results[index];
                return ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.red),
                  title: Text(
                    place['name'] as String,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    place['address'] as String,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    final pos = LatLng(
                      (place['lat'] as num).toDouble(),
                      (place['lng'] as num).toDouble(),
                    );
                    _controller.text = place['name'] as String;
                    setState(() => _results = []);
                    widget.onPlaceSelected(place['name'] as String, pos);
                  },
                );
              },
            ),
          ),

        if (_isSearching)
          const Padding(
            padding: EdgeInsets.all(8),
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }
}
