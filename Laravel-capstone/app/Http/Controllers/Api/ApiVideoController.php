<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Video;
use Illuminate\Http\Request;

class ApiVideoController extends Controller
{
    // Get all videos for mobile app
    public function index(Request $request)
    {
        $query = Video::orderBy('created_at', 'desc');
        
        // Search functionality
        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                  ->orWhere('description', 'like', "%{$search}%");
            });
        }
        
        // Pagination
        $perPage = $request->per_page ?? 10;
        $videos = $query->paginate($perPage);
        
        return response()->json([
            'success' => true,
            'data' => $videos
        ]);
    }
    
    // Get featured videos
    public function featured()
    {
        $videos = Video::where('is_featured', true)
                     ->orderBy('created_at', 'desc')
                     ->take(5)
                     ->get();
        
        return response()->json([
            'success' => true,
            'data' => $videos
        ]);
    }
    
    // Get a specific video
    public function show($id)
    {
        $video = Video::findOrFail($id);
        
        // Increment view count
        $video->views = $video->views + 1;
        $video->save();
        
        return response()->json([
            'success' => true,
            'data' => $video
        ]);
    }
    
    // Like a video
    public function likeVideo(Request $request, $id)
    {
        $video = Video::findOrFail($id);
        $user = $request->user();
        
        // Check if user already liked this video
        if ($user->likedVideos()->where('video_id', $id)->exists()) {
            // Unlike the video
            $user->likedVideos()->detach($id);
            $message = 'Video unliked successfully';
        } else {
            // Like the video
            $user->likedVideos()->attach($id);
            $message = 'Video liked successfully';
        }
        
        // Update like count
        $video->likes = $video->likes()->count();
        $video->save();
        
        return response()->json([
            'success' => true,
            'message' => $message,
            'data' => [
                'likes' => $video->likes,
                'liked_by_user' => $user->likedVideos()->where('video_id', $id)->exists()
            ]
        ]);
    }
    
    // Get related videos
    public function relatedVideos($id)
    {
        $video = Video::findOrFail($id);
        
        // Get videos with similar title or description
        $relatedVideos = Video::where('id', '!=', $id)
                            ->where(function($query) use ($video) {
                                $query->where('title', 'like', "%{$video->title}%")
                                      ->orWhere('description', 'like', "%{$video->description}%");
                            })
                            ->orderBy('created_at', 'desc')
                            ->take(5)
                            ->get();
        
        // If not enough related videos, get latest videos
        if ($relatedVideos->count() < 5) {
            $additionalVideos = Video::where('id', '!=', $id)
                                   ->whereNotIn('id', $relatedVideos->pluck('id'))
                                   ->orderBy('created_at', 'desc')
                                   ->take(5 - $relatedVideos->count())
                                   ->get();
            
            $relatedVideos = $relatedVideos->merge($additionalVideos);
        }
        
        return response()->json([
            'success' => true,
            'data' => $relatedVideos
        ]);
    }
}