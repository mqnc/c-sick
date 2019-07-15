#include <cassert>
#include <deque>
#include <iostream>
#include <string>
#include <type_traits>
#include <vector>
#include "noisy.hpp"

struct Record
{
    union {
        void* target;
        Record* nextRecord;
    };
    std::size_t count{0};
};

class Registry
{
    constexpr static std::size_t CHUNK{64};

public:
    static Registry sRegistry;

    Record& take(void* target)
    {
        if (!mFreeRecord) {
            mRecords.resize(1 + mRecords.size());
            mFreeRecord = &mRecords.back();
        }
        Record& res{*mFreeRecord};
        mFreeRecord = res.nextRecord;
        assert(0 == res.count);
        res.target = target;
        return res;
    }

    constexpr void retain(Record& record)
    {
        record.count += 1;
    }

    constexpr void put(Record& record)
    {
        assert(0 == record.count);
        record.nextRecord = mFreeRecord;
        mFreeRecord = &record;
    }

    constexpr void release(Record& record)
    {
        assert(0 < record.count);
        record.count -= 1;
        if (0 == record.count) {
            put(record);
        }
    }

private:
    std::deque<Record> mRecords{};
    Record* mFreeRecord{nullptr};
};

/**
 * I take care of reference counting for registry slots.
 */
class SlotRef
{
public:

/**
 * I own a registry slot. I am empty after initialisation and
 * consume at most one registry slot.
 */

    class Owner;

private:
    constexpr explicit SlotRef(Record& record) noexcept
    : mRecord{&record}
    {
        Registry::sRegistry.retain(record);
    }

public:
    constexpr SlotRef(SlotRef const& slotRef) noexcept
    : SlotRef{*slotRef.mRecord}
    {}

    constexpr SlotRef& operator =(SlotRef const& slotRef) noexcept
    {
        Registry::sRegistry.retain(*slotRef.mRecord);
        Registry::sRegistry.release(*mRecord);
        mRecord = slotRef.mRecord;
        return *this;
    }

    ~SlotRef() noexcept
    {
        Registry::sRegistry.release(*mRecord);
    }

    constexpr Record* operator ->() const noexcept
    {
        return mRecord;
    }

private:
    Record* mRecord{nullptr};
};

class SlotRef::Owner
{
public:
    Owner() = default;
    Owner(Owner const&) = delete;
    Owner& operator =(Owner const&) = delete;

    ~Owner() noexcept {
        if (mRecord) {
            mRecord->target = nullptr;
            Registry::sRegistry.release(*mRecord);
        }
    }

    SlotRef get(void* const target)
    {
        if (!mRecord) {
            mRecord = &Registry::sRegistry.take(target);
            Registry::sRegistry.retain(*mRecord);
        }
        assert(target == mRecord->target);
        return SlotRef{*mRecord};
    }

private:
    Record* mRecord{nullptr};
};

/**
 * A VolatilePointer represents an entity in the registry. It becomes invalid
 * when that entity expires.
 */
template<typename Value>
class VolatilePtr
{
public:
    constexpr VolatilePtr(SlotRef const& slotRef) noexcept
    : mSlotRef{slotRef}
    {}

    constexpr Value* get() const noexcept
    {
        return static_cast<Value*>(mSlotRef->target);
    }

    constexpr Value& operator *() const noexcept
    {
        return *get();
    }

    constexpr Value* operator ->() const noexcept
    {
        return get();
    }

private:
    SlotRef mSlotRef;
};

/**
 * Target holds an instance of Value. It can provide pointers from a registry
 * which are invalidated when the instance is destroyed.
 */
template<typename Value>
class Target
{
public:
    struct forwardCtor {};

/**
 * Convenience function for invoking forwarding c'tor.
 */

    template<typename ...Args>
    static constexpr Target create(Args&& ...args)
    {
        return Target(forwardCtor{}, std::forward<Args>(args)...);
    }

/**
 * This constructor forwards its parameters to Value's c'tor, constructing
 * the instance in-place.
 */

    template<typename ...Args>
    constexpr explicit Target(forwardCtor, Args&& ...args)
    : mValue{std::forward<Args>(args)...}
    , mOwner{}
    {}

    Target(Target const& target) noexcept(std::is_nothrow_copy_constructible_v<Value>)
    : mValue{target.mValue}
    , mOwner{}
    {}

    Target(Target&& target) noexcept(std::is_nothrow_move_constructible_v<Value>)
    : mValue{std::forward<decltype(target.mValue)>(target.mValue)}
    , mOwner{}
    {}

    Target& operator =(Target const& target) noexcept(std::is_nothrow_copy_assignable_v<Value>)
    {
        mValue = target.mValue;
        // Omit mOwner since it's a reference to ourselves.
        return *this;
    }

    Target& operator =(Target&& target) noexcept(std::is_nothrow_move_assignable_v<Value>)
    {
        mValue = std::forward<decltype(target.mValue)>(target.mValue);
        // Omit mOwner since it's a reference to ourselves.
        return *this;
    }

    template<typename U>
    Target& operator =(Target<U> const& target)
    {
        mValue = target.mValue;
        // Omit mOwner since it's a reference to ourselves.
        return *this;
    }

    constexpr auto& operator *() const noexcept
    {
        return mValue;
    }

    constexpr auto operator ->() const noexcept
    {
        return &mValue;
    }

    /**
     * Yields a volatile pointer to the Value of this object which
     * expires when it is destroyed.
     */
    VolatilePtr<Value> ptr()
    {
        return VolatilePtr<Value>{mOwner.get(&mValue)};
    }

private:
    Value mValue{};
    SlotRef::Owner mOwner{};
};

Registry Registry::sRegistry{};

/**
 * @return A volatile pointer to a local variable.
 */
VolatilePtr<Noisy> foo()
{
    std::cout << '\n' << R"(auto stack{Target<Noisy>::create("Stackbert")};)" << '\n';
    auto stack{Target<Noisy>::create("Stackbert")};

    std::cout << "stack=" << stack->name << '\n';

    std::cout << '\n' << R"(auto stackRef{stack.ptr()};)" << '\n';
    auto stackRef{stack.ptr()};

    std::cout << "stackRef=" << stackRef->name << '\n';

    return stackRef;
}

int main()
{
    std::cout << '\n' << R"(auto stackRef{foo()};)" << '\n';
    auto stackRef{foo()};

    std::cout << "stackRef=" << stackRef.get() << '\n';

    std::cout << '\n' << R"(std::vector<Target<Noisy>> noisies{"Vectorbert"};)" << '\n';
    std::vector<Target<Noisy>> noisies{};
    noisies.emplace_back(Target<Noisy>::forwardCtor{}, "Vectorbert");

    std::cout << '\n' << R"(auto vecRef{noisies.front().ptr()};)" << '\n';
    auto vecRef{noisies.front().ptr()};
    std::cout << "vecRef=" << vecRef->name << '\n';

    std::cout << '\n' << R"(for (int i{0}; i != 4; ++i) {)" << '\n';
    for (int i{0}; i != 4; ++i) {
        noisies.emplace_back(Target<Noisy>::forwardCtor{}, "goodbye");
    }
    std::cout << "vecRef=" << vecRef.get() << '\n';

    std::cout << '\n' << R"(return 0;)" << '\n';
    return 0;
}
