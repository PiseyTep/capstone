<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\ResourceCollection;

class VideoCollection extends ResourceCollection
{
    /**
     * Transform the resource collection into an array.
     *
     * @return array<int|string, mixed>
     */
    public function toArray(Request $request): array
{
    return [
        'data' => $this->collection,
        'links' => [
            'first' => $this->url(1),
            'last' => $this->url($this->lastPage()),
            'prev' => $this->previousPageUrl(),
            'next' => $this->nextPageUrl(),
        ],
        'meta' => [
            'current_page' => $this->currentPage(),
            'total' => $this->total(),
            'per_page' => $this->perPage(),
        ]
    ];
}
}
