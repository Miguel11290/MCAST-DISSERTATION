INCOMPATIBLE_GROUPS = {
    "oxidizer": {"fuel", "metal_powder"},
    "fuel": {"oxidizer"},
    "metal_powder": {"oxidizer"},
    "binder": set(),
    "other": set()
}

def are_incompatible(group_a: str | None, group_b: str | None) -> bool:
    if not group_a or not group_b:
        return False
    
    a = group_a.strip().lower()
    b = group_b.strip().lower()
    
    return b in INCOMPATIBLE_GROUPS.get(a, set())