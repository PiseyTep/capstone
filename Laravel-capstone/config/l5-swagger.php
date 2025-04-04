<?php

return [
    'default' => 'default',
    'constants' => [
    'API_HOST' => env('L5_SWAGGER_CONST_HOST', 'http://localhost:8000'),
],
    'documentations' => [
        'default' => [
            'api' => [
                'title' => 'Video API Documentation',
                'description' => 'API for managing video resources',
                'version' => '1.0.0',
            ],
            'routes' => [
                'api' => 'api/documentation',
            ],
            'paths' => [
                 // All possible keys the package might check
                 'base' => env('L5_SWAGGER_BASE_PATH', null), // <-- Added base
                 'excludes' => [], // <-- Empty array to satisfy check
                'docs' => storage_path('api-docs'), // <-- This was missing
                'docs_json' => 'api-docs.json',
                'docs_yaml' => 'api-docs.yaml',
                'format_to_use_for_docs' => 'json',
                'annotations' => [
                    base_path('app/Http/Controllers'),
                    base_path('app/Models'),
                ],
                'swagger_ui_assets_path' => 'vendor/swagger-api/swagger-ui/dist/',
            ],
        ],
    ],

    'defaults' => [
        'routes' => [
            'docs' => 'docs',
            'oauth2_callback' => 'api/oauth2-callback',
            'middleware' => [
                'api' => [],
                'docs' => [],
            ],
        ],
        
        'scanOptions' => [
            'exclude' => [
                base_path('vendor'),
                base_path('storage'),
                base_path('tests'),
            ],
        ],
        
        'securityDefinitions' => [
            'securitySchemes' => [
                'bearerAuth' => [
                    'type' => 'http',
                    'scheme' => 'bearer',
                    'bearerFormat' => 'JWT',
                ],
            ],
        ],
        
        'ui' => [
            'display' => [
                'doc_expansion' => 'none',
                'filter' => true,
            ],
        ],
    ],
];