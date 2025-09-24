<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Membership;
use App\Models\UserMembership;
use Carbon\Carbon;
use Illuminate\Database\Seeder;

class UserMembershipSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        // Get a test user - you can replace this with the ID of a specific user you want to assign membership to
        // In this example, I'm looking for the South River user (ID 147) mentioned in your API response
        $user = User::where('id', 147)->first();
        
        // If the user doesn't exist, get the first user or skip
        if (!$user) {
            $user = User::first();
            if (!$user) {
                $this->command->info('No users found to assign membership.');
                return;
            }
        }
        
        // Get the Premium membership plan
        $membership = Membership::where('title', 'Premium Plan')->first();
        
        // If the membership doesn't exist, get the first one or skip
        if (!$membership) {
            $membership = Membership::first();
            if (!$membership) {
                $this->command->info('No membership plans found to assign to users.');
                return;
            }
        }
        
        // Deactivate any existing memberships for this user
        UserMembership::where('user_id', $user->id)
            ->where('is_active', true)
            ->update(['is_active' => false]);
        
        // Create a new membership for the user
        $startDate = Carbon::now();
        $endDate = Carbon::now()->add($membership->duration, $membership->duration_unit);
        
        UserMembership::create([
            'user_id' => $user->id,
            'membership_id' => $membership->id,
            'start_date' => $startDate,
            'end_date' => $endDate,
            'is_active' => true,
        ]);
        
        $this->command->info("Membership '{$membership->title}' assigned to user {$user->firstname} {$user->lastname} (ID: {$user->id}).");
    }
}
