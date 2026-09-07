<?php

namespace App\Helpers;

class ResponseHelpers
{
    public static function success($data = null, $message = 'Success', $status = 200)
    {
        return response()->json([
            'data' => $data,
            'status' => $status,
            'message' => $message
        ], $status);
    }    public static function error($message = 'Error', $status = 400)
    {
        return response()->json([
            'status' => $status,
            'message' => $message
        ], $status);
    }
}
