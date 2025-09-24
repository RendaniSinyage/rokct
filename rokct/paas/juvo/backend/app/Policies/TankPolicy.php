namespace App\Policies;

use App\Models\Resources\Tank;
use App\Models\User;

class TankPolicy
{
    public function viewAny(User $user): bool
    {
        return true; // Further restrict if needed
    }

    public function view(User $user, Tank $tank): bool
    {
        return $user->shops()->where('id', $tank->shop_id)->exists();
    }

    public function create(User $user): bool
    {
        return true; // Further restrict if needed
    }

    public function update(User $user, Tank $tank): bool
    {
        return $user->shops()->where('id', $tank->shop_id)->exists();
    }

    public function delete(User $user, Tank $tank): bool
    {
        return $user->shops()->where('id', $tank->shop_id)->exists();
    }
}
