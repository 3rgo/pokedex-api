<?php

namespace Database\Seeders;

// use Illuminate\Database\Console\Seeds\WithoutModelEvents;

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
    }
}
