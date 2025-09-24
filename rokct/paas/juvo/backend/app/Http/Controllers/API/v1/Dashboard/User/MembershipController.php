<?php
// app/Http/Controllers/API/v1/Dashboard/User/MembershipController.php
namespace App\Http\Controllers\API\v1\Dashboard\User;

use App\Helpers\ResponseError;
use App\Http\Resources\MembershipResource;
use App\Http\Resources\UserResource;
use App\Models\Membership;
use App\Models\User;
use App\Models\UserMembership;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MembershipController extends UserBaseController
{
    /**
     * Get all available membership plans
     */
    public function plans(): JsonResponse
    {
        $plans = Membership::where('is_active', true)->get();
        
        return $this->successResponse(
            __('errors.' . ResponseError::SUCCESS, locale: $this->language),
            MembershipResource::collection($plans)
        );
    }
    
    /**
     * Subscribe user to a membership plan
     */
    public function subscribe(Request $request): JsonResponse
    {
        $request->validate([
            'membership_id' => 'required|exists:memberships,id',
        ]);
        
        $user = User::find(auth('sanctum')->id());
        if (!$user) {
            return $this->onErrorResponse([
                'code' => ResponseError::ERROR_404,
                'message' => __('errors.' . ResponseError::ERROR_404, locale: $this->language)
            ]);
        }
        
        $membership = Membership::find($request->membership_id);
        if (!$membership || !$membership->is_active) {
            return $this->onErrorResponse([
                'code' => ResponseError::ERROR_404,
                'message' => 'Membership plan not found or not active'
            ]);
        }
        
        // Deactivate any existing membership
        UserMembership::where('user_id', $user->id)
            ->where('is_active', true)
            ->update(['is_active' => false]);
        
        // Start date is now, end date is calculated based on the membership duration
        $startDate = Carbon::now();
        $endDate = Carbon::now()->add($membership->duration, $membership->duration_unit);
        
        // Create new membership
        UserMembership::create([
            'user_id' => $user->id,
            'membership_id' => $membership->id,
            'start_date' => $startDate,
            'end_date' => $endDate,
            'is_active' => true,
        ]);
        
        // Reload the user with the new membership
        $user->load('userMembership.membership');
        
        return $this->successResponse(
            __('errors.' . ResponseError::SUCCESS, locale: $this->language),
            UserResource::make($user)
        );
    }
    
    /**
     * Cancel user's membership
     */
    public function cancel(): JsonResponse
    {
        $user = User::find(auth('sanctum')->id());
        if (!$user) {
            return $this->onErrorResponse([
                'code' => ResponseError::ERROR_404,
                'message' => __('errors.' . ResponseError::ERROR_404, locale: $this->language)
            ]);
        }
        
        // Deactivate any existing membership
        $updated = UserMembership::where('user_id', $user->id)
            ->where('is_active', true)
            ->update(['is_active' => false]);
        
        if (!$updated) {
            return $this->onErrorResponse([
                'code' => ResponseError::ERROR_404,
                'message' => 'No active membership found'
            ]);
        }
        
        // Reload the user without the active membership
        $user->load('userMembership.membership');
        
        return $this->successResponse(
            'Membership successfully cancelled',
            UserResource::make($user)
        );
    }
}
