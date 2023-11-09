<?php

namespace App\Http\Controllers;

use App\Models\Type;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Response;
use OpenApi\Attributes as OA;

class ListTypes extends Controller
{
    #[OA\Get(
        path: '/types',
        summary: 'Types',
        description: 'Fetches all available types.',
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
            'data'    => Type::all()
        ]);
    }
}
