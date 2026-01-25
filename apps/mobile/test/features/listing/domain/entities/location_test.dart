import 'package:flutter_test/flutter_test.dart';
import 'package:tekka/features/listing/domain/entities/location.dart';

void main() {
  group('Division', () {
    test('fromJson creates instance correctly', () {
      final json = {
        'id': 'div-1',
        'cityId': 'city-1',
        'name': 'Makindye',
        'isActive': true,
        'sortOrder': 1,
      };

      final division = Division.fromJson(json);

      expect(division.id, 'div-1');
      expect(division.cityId, 'city-1');
      expect(division.name, 'Makindye');
      expect(division.isActive, true);
      expect(division.sortOrder, 1);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'div-1',
        'cityId': 'city-1',
        'name': 'Nakawa',
      };

      final division = Division.fromJson(json);

      expect(division.isActive, true);
      expect(division.sortOrder, 0);
      expect(division.city, isNull);
    });

    test('fromJson handles nested city', () {
      final json = {
        'id': 'div-1',
        'cityId': 'city-1',
        'name': 'Makindye',
        'city': {
          'id': 'city-1',
          'name': 'Kampala',
        },
      };

      final division = Division.fromJson(json);

      expect(division.city, isNotNull);
      expect(division.city!.name, 'Kampala');
    });

    test('toJson returns correct map', () {
      final division = Division(
        id: 'div-1',
        cityId: 'city-1',
        name: 'Makindye',
        isActive: true,
        sortOrder: 1,
      );

      final json = division.toJson();

      expect(json['id'], 'div-1');
      expect(json['cityId'], 'city-1');
      expect(json['name'], 'Makindye');
      expect(json['isActive'], true);
      expect(json['sortOrder'], 1);
    });

    test('equality based on id', () {
      final division1 = Division(
        id: 'div-1',
        cityId: 'city-1',
        name: 'Makindye',
      );

      final division2 = Division(
        id: 'div-1',
        cityId: 'city-1',
        name: 'Makindye Updated',
      );

      final division3 = Division(
        id: 'div-2',
        cityId: 'city-1',
        name: 'Makindye',
      );

      expect(division1, equals(division2));
      expect(division1, isNot(equals(division3)));
    });
  });

  group('City', () {
    test('fromJson creates instance correctly', () {
      final json = {
        'id': 'city-1',
        'name': 'Kampala',
        'isActive': true,
        'sortOrder': 1,
        'divisions': [
          {'id': 'div-1', 'cityId': 'city-1', 'name': 'Makindye'},
          {'id': 'div-2', 'cityId': 'city-1', 'name': 'Nakawa'},
        ],
      };

      final city = City.fromJson(json);

      expect(city.id, 'city-1');
      expect(city.name, 'Kampala');
      expect(city.isActive, true);
      expect(city.sortOrder, 1);
      expect(city.divisions.length, 2);
      expect(city.divisions[0].name, 'Makindye');
      expect(city.divisions[1].name, 'Nakawa');
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'city-1',
        'name': 'Kampala',
      };

      final city = City.fromJson(json);

      expect(city.isActive, true);
      expect(city.sortOrder, 0);
      expect(city.divisions, isEmpty);
    });

    test('activeDivisions filters inactive and sorts by sortOrder', () {
      final city = City(
        id: 'city-1',
        name: 'Kampala',
        divisions: [
          Division(
            id: 'div-1',
            cityId: 'city-1',
            name: 'Rubaga',
            sortOrder: 3,
            isActive: true,
          ),
          Division(
            id: 'div-2',
            cityId: 'city-1',
            name: 'Inactive Division',
            sortOrder: 1,
            isActive: false,
          ),
          Division(
            id: 'div-3',
            cityId: 'city-1',
            name: 'Makindye',
            sortOrder: 1,
            isActive: true,
          ),
          Division(
            id: 'div-4',
            cityId: 'city-1',
            name: 'Nakawa',
            sortOrder: 2,
            isActive: true,
          ),
        ],
      );

      final activeDivisions = city.activeDivisions;

      expect(activeDivisions.length, 3);
      expect(activeDivisions[0].name, 'Makindye'); // sortOrder: 1
      expect(activeDivisions[1].name, 'Nakawa'); // sortOrder: 2
      expect(activeDivisions[2].name, 'Rubaga'); // sortOrder: 3
    });

    test('toJson returns correct map', () {
      final city = City(
        id: 'city-1',
        name: 'Kampala',
        isActive: true,
        sortOrder: 1,
        divisions: [
          Division(
            id: 'div-1',
            cityId: 'city-1',
            name: 'Makindye',
          ),
        ],
      );

      final json = city.toJson();

      expect(json['id'], 'city-1');
      expect(json['name'], 'Kampala');
      expect(json['isActive'], true);
      expect(json['sortOrder'], 1);
      expect(json['divisions'], isA<List>());
      expect((json['divisions'] as List).length, 1);
    });

    test('equality based on id', () {
      final city1 = City(id: 'city-1', name: 'Kampala');
      final city2 = City(id: 'city-1', name: 'Kampala Updated');
      final city3 = City(id: 'city-2', name: 'Kampala');

      expect(city1, equals(city2));
      expect(city1, isNot(equals(city3)));
    });
  });

  group('SelectedLocation', () {
    test('displayText shows city only when no division', () {
      final city = City(id: 'city-1', name: 'Kampala');
      final location = SelectedLocation(city: city);

      expect(location.displayText, 'Kampala');
    });

    test('displayText shows city and division when both provided', () {
      final city = City(id: 'city-1', name: 'Kampala');
      final division = Division(id: 'div-1', cityId: 'city-1', name: 'Makindye');
      final location = SelectedLocation(city: city, division: division);

      expect(location.displayText, 'Kampala, Makindye');
    });

    test('cityId returns correct value', () {
      final city = City(id: 'city-123', name: 'Kampala');
      final location = SelectedLocation(city: city);

      expect(location.cityId, 'city-123');
    });

    test('divisionId returns null when no division', () {
      final city = City(id: 'city-1', name: 'Kampala');
      final location = SelectedLocation(city: city);

      expect(location.divisionId, isNull);
    });

    test('divisionId returns correct value when division provided', () {
      final city = City(id: 'city-1', name: 'Kampala');
      final division = Division(id: 'div-456', cityId: 'city-1', name: 'Makindye');
      final location = SelectedLocation(city: city, division: division);

      expect(location.divisionId, 'div-456');
    });
  });
}
