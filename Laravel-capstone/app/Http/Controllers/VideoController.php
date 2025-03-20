<?php

namespace App\Http\Controllers;

use App\Models\Video;
use Illuminate\Http\Request;

class VideoController extends Controller
{

    //Get all videos
    public function index()
    {
        return response()->json(Video::all());
    }
    // Store a new video
    public function store(Request $request)
    {
        $request->validate([
            'title' => 'required|string',
            'description' => 'required|string',
            'url' => 'required|string',
        ]);

        $video = Video::create($request->all());

        return response()->json(['message' => 'Video added successfully', 'video' => $video], 201);
    }

    public function show($id)
    {
        return response()->json(Video::findOrFail($id));
    }
    // Update a video
    public function update(Request $request, $id)
    {
        $video = Video::findOrFail($id);
        $video->update($request->all());

        return response()->json($video);
    }
    // Delete a video
    public function destroy($id)
    {
        Video::destroy($id);

        return response()->json(['message' => 'Video deleted']);
    }
}
