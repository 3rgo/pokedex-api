<?php

namespace App\Http\Controllers;

use App\Http\Resources\PokemonResource;
use App\Models\Pokemon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Response;
use OpenApi\Attributes as OA;

class ListPokemon extends Controller
{
    #[OA\Get(
        path: '/pokemon',
        summary: 'Pokemon',
        description: 'Fetches all available pokemon.',
        parameters: [],
        responses: [
            new OA\Response(response: 200, description: 'OK: Data is returned as an array'),
        ]
    )]
    /**
     * Handle the incoming request.
     */
    public function __invoke(Request $request)
    {
        return Response::json([
            'success' => true,
            'data'    => PokemonResource::collection(Pokemon::with([
                'types',
                'evolvedFrom',
                'evolvesTo'
            ])->get())
        ]);
    }
}
