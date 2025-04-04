<?php

namespace App\Http\Controllers;

use App\Models\Video;
use App\Http\Resources\VideoResource;
use App\Http\Resources\VideoCollection;
use Illuminate\Http\Request;

/**
 * @OA\Info(
 *     title="Video API",
 *     version="1.0.0",
 *     description="API for managing video resources"
 * )
 *
 * @OA\Server(
 *      url="http://localhost:8000",
 *     description="API Server"
 * )
 *
 * @OA\Tag(
 *     name="Videos",
 *     description="All video endpoints"
 * )
 *
 * @OA\Schema(
 *     schema="Video",
 *     @OA\Property(property="id", type="integer", example=1),
 *     @OA\Property(property="title", type="string", example="Sample Video"),
 *     @OA\Property(property="description", type="string", example="Video description"),
 *     @OA\Property(property="url", type="string", format="url", example="https://example.com/video.mp4"),
 *     @OA\Property(property="created_at", type="string", format="date-time"),
 *     @OA\Property(property="updated_at", type="string", format="date-time")
 * )
 *
 * @OA\Schema(
 *     schema="VideoInput",
 *     required={"title", "url"},
 *     @OA\Property(property="title", type="string", maxLength=255, example="New Video"),
 *     @OA\Property(property="description", type="string", maxLength=1000, example="Video description"),
 *     @OA\Property(property="url", type="string", format="url", maxLength=255, example="https://example.com/new-video.mp4")
 * )
 */
class VideoController extends Controller
{
    /**
     * @OA\Get(
     *     path="/videos",
     *     summary="List all videos",
     *     tags={"Videos"},
     *     @OA\Response(
     *         response=200,
     *         description="Successful operation",
     *         @OA\JsonContent(ref="#/components/schemas/Video")
     *     ),
     *     @OA\Response(response=500, description="Server error")
     * )
     */
    public function index()
    {
        return new VideoCollection(Video::paginate(10));
    }

    /**
     * @OA\Post(
     *     path="/videos",
     *     summary="Create a video",
     *     tags={"Videos"},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(ref="#/components/schemas/VideoInput")
     *     ),
     *     @OA\Response(
     *         response=201,
     *         description="Video created",
     *         @OA\JsonContent(ref="#/components/schemas/Video")
     *     ),
     *     @OA\Response(response=422, description="Validation error")
     * )
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'required|string|max:1000',
            'url' => 'required|url|max:255|unique:videos',
        ]);

        return new VideoResource(Video::create($validated));
    }

    /**
     * @OA\Get(
     *     path="/videos/{id}",
     *     summary="Get a video",
     *     tags={"Videos"},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         required=true,
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Video found",
     *         @OA\JsonContent(ref="#/components/schemas/Video")
     *     ),
     *     @OA\Response(response=404, description="Video not found")
     * )
     */
    public function show(Video $video)
    {
        $video->load('user', 'comments');
        return new VideoResource($video);
    }

    /**
     * @OA\Put(
     *     path="/videos/{id}",
     *     summary="Update a video",
     *     tags={"Videos"},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         required=true,
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(ref="#/components/schemas/VideoInput")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Video updated",
     *         @OA\JsonContent(ref="#/components/schemas/Video")
     *     ),
     *     @OA\Response(response=404, description="Video not found"),
     *     @OA\Response(response=422, description="Validation error")
     * )
     */
    public function update(Request $request, Video $video)
    {
        $validated = $request->validate([
            'title' => 'sometimes|string|max:255',
            'description' => 'sometimes|string|max:1000',
            'url' => 'sometimes|url|max:255|unique:videos,url,'.$video->id,
        ]);

        $video->update($validated);

        return new VideoResource($video);
    }

    /**
     * @OA\Delete(
     *     path="/videos/{id}",
     *     summary="Delete a video",
     *     tags={"Videos"},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         required=true,
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(response=204, description="Video deleted"),
     *     @OA\Response(response=404, description="Video not found")
     * )
     */
    public function destroy(Video $video)
    {
        $video->delete();
        return response()->json(null, 204);
    }
}