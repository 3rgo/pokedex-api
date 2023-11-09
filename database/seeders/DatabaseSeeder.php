<?php

namespace Database\Seeders;

// use Illuminate\Database\Console\Seeds\WithoutModelEvents;

use App\Models\Pokemon;
use App\Models\Type;
use Illuminate\Database\Seeder;
use Illuminate\Support\Arr;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $types = [];

        // Import types
        $json = json_decode(file_get_contents(database_path('seeders/fixtures/types.json')), true);
        foreach ($json as $item) {
            $type = Type::create([
                'name'  => Arr::only($item['name'], ['fr', 'en']),
                'image' => $item['sprites']
            ]);
            $types[$item['name']['fr']] = $type->fresh();
        }
        unset($json);

        // Import Pokemons
        $pokemon = [];
        $evolutions = [];
        $json = json_decode(file_get_contents(database_path('seeders/fixtures/pokemon.json')), true);
        foreach ($json as $item) {
            $pokemon = Pokemon::create([
                'id'          => $item['pokedexId'],
                'generation'  => $item['generation'],
                'name'        => Arr::only($item['name'], ['fr', 'en']),
                'image'       => $item['sprites']['regular'],
                'image_shiny' => $item['sprites']['shiny'],
                'height'      => floatval(str_replace(',', '.', $item['height'])),
                'weight'      => floatval(str_replace(',', '.', $item['weight'])),
                'stats'       => $item['stats'],
            ]);
            foreach ($item['types'] as $type) {
                $pokemon->types()->attach($types[$type['name']]);
            }
            $pokemon->refresh();
            $pokemons[$pokemon['id']] = $pokemon;

            foreach (($item['evolution']['next'] ?? []) as $evolution) {
                $evolutionId = $evolution['pokedexId'];
                if (array_key_exists($evolutionId, $pokemons)) {
                    $pokemon->evolvedFrom()->attach($evolution['pokedexId'], ['condition' => $evolution['condition'] ?? '']);
                } else {
                    $evolutions[] = [
                        'from'      => $pokemon['id'],
                        'to'        => $evolutionId,
                        'condition' => $evolution['condition']
                    ];
                }
            }
        }

        usort($evolutions, fn ($a, $b) => $a['from'] <=> $b['from']);

        foreach ($evolutions as $evolution) {
            $fromPokemon = Pokemon::find($evolution['from']);
            $fromPokemon->evolvesTo()->attach($evolution['to'], ['condition' => $evolution['condition']]);
        }
    }
}
