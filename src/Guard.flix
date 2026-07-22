enum Guard[r: Region](Ref[Bool, r])

// like a lock but not for concurrency
mod Guard {
    pub def withGuard(f: Unit -> a \ ef, g: Guard[r]): a \ r + ef = {
        let Guard(ref) = g;
        let oldVal = Ref.get(ref);
        Ref.put(true, ref);
        let res = f();
        Ref.put(oldVal, ref);
        res
    }

    pub def fresh(rc: Region[r]): Guard[r] \ r = {
        Guard(Ref.fresh(rc, false))
    }

    pub def ifOpen(f: Unit -> Unit \ ef, g: Guard[r]): Unit \ r + ef = {
        let Guard(ref) = g;
        if (not Ref.get(ref)) {
            f()
        }
    }
}