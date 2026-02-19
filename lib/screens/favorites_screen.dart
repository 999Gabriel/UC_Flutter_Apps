import 'package:flutter/material.dart';

/// Bildschirm zur Anzeige und Verwaltung der Favoriten-Städte
class FavoritesScreen extends StatefulWidget {
  final List<String> favorites;
  final Function(String) onCitySelected;
  final Function(String) onCityRemoved;

  const FavoritesScreen({
    super.key,
    required this.favorites,
    required this.onCitySelected,
    required this.onCityRemoved,
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late List<String> _favorites;

  @override
  void initState() {
    super.initState();
    _favorites = List.from(widget.favorites);
  }

  /// Stadt aus der Favoritenliste entfernen
  void _removeCity(String city) {
    setState(() {
      _favorites.remove(city);
    });
    widget.onCityRemoved(city);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'FAVORITEN',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: Container(
          margin: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, size: 22),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0a0a0a),
              Color(0xFF000000),
            ],
          ),
        ),
        child: _favorites.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border_rounded,
                      size: 80,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Keine Favoriten',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tippe auf das Herz-Symbol, um\nStädte zu deinen Favoriten hinzuzufügen.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
                itemCount: _favorites.length,
                itemBuilder: (context, index) {
                  final city = _favorites[index];
                  return _buildFavoriteItem(city, index);
                },
              ),
      ),
    );
  }

  /// Einzelnes Favoriten-Element im WSJ-Stil
  Widget _buildFavoriteItem(String city, int index) {
    return GestureDetector(
      onTap: () {
        // Stadt auswählen und zurück zum HomeScreen navigieren
        widget.onCitySelected(city);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Row(
          children: [
            // Stadtname
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    city.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tippen zum Laden',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            // Löschen-Button
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
              child: IconButton(
                onPressed: () => _removeCity(city),
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white.withOpacity(0.5),
                  size: 20,
                ),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

