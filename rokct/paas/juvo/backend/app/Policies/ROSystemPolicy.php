namespace App\Policies;

use App\Models\Resources\ROSystem;
use App\Models\User;

class ROSystemPolicy
{
    public function view(User $user, ROSystem $roSystem): bool
    {
        return $user->shops()->where('id', $roSystem->shop_id)->exists();
    }

    public function create(User $user): bool
    {
        return true; // Further restrict if needed
    }
}
