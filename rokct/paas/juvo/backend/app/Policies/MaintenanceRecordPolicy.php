namespace App\Policies;

use App\Models\Resources\MaintenanceRecord;
use App\Models\User;

class MaintenanceRecordPolicy
{
    public function viewAny(User $user): bool
    {
        return true; // Further restrict if needed
    }

    public function create(User $user): bool
    {
        return true; // Further restrict if needed
    }

    public function view(User $user, MaintenanceRecord $record): bool
    {
        return $user->shops()->where('id', $record->shop_id)->exists();
    }
}
