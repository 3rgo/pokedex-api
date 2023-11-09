<?php

namespace App\Http\Controllers;

use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Illuminate\Foundation\Validation\ValidatesRequests;
use Illuminate\Routing\Controller as BaseController;
use OpenApi\Attributes as OA;

#[OA\Info(
    title: 'Pokédex API',
    version: '1.0'
)]
#[OA\Server(url: '/api')]

class Controller extends BaseController
{
    use AuthorizesRequests, ValidatesRequests;
}
