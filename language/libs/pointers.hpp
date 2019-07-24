#include <cassert>
#include <deque>
#include <iostream>
#include <string>
#include <type_traits>
#include <vector>
#include "noisy.hpp"

/**
 * I manage dynamically allocated, reference-counted slots.
 *
 * Each slot stores one pointer.
 */

class Registry
{
    constexpr static std::size_t CHUNK{64};

public:

/**
 * Storage for a reference-counted pointer value.
 *
 * When a slot is not in use, 0 == count and nextRecord points to the next
 * free record, or nullptr if none.
 */

    struct Record
    {
        std::size_t count{0};
        union {
            void* target;
            Record* nextRecord;
        };
    };

/**
 * The single global instance of the registry.
 */

    static Registry sRegistry;

/**
 * Get a record pointing to the given target from the registry.
 *
 * @param target The target to store in the slot.
 * @return A record whose reference count is zero that refers to the given
 * point.
 */

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

/**
 * Increase the reference count of the given record.
 *
 * @param record The record to retain.
 */

    constexpr void retain(Record& record)
    {
        record.count += 1;
    }

/**
 * Return the given record to the registry.
 *
 * @note Must only be called for records which were just take()n whose
 * reference count is still zero.
 * @param record The record to return.
 */

    constexpr void put(Record& record)
    {
        assert(0 == record.count);
        record.nextRecord = mFreeRecord;
        mFreeRecord = &record;
    }

/**
 * Release the given record.
 *
 * @note Calls put() when the record's reference count reaches zero.
 * @param record The record to release.
 */

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
 *
 * Instances can only be created by Owner's get() method and always refer
 * to exactly one registry slot over their lifetime. The registry slot is
 * retained on creation and released (and possibly returned) on
 * destruction.
 */

class SlotRef
{
public:

    class Owner;

private:
    constexpr explicit SlotRef(Registry::Record& record) noexcept
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

/**
 * @return A pointer to the referenced registry record.
 */

    constexpr Registry::Record* operator ->() const noexcept
    {
        return mRecord;
    }

private:
    Registry::Record* mRecord{nullptr};
};


/**
 * I own a registry slot.
 *
 * I am empty after initialisation and consume at most one registry slot
 * when given a target pointer. I provide counted references to that slot
 * that remain valid even after I have expired and cleared the stored
 * target pointer.
 */

class SlotRef::Owner
{
public:
    Owner() = default;

/**
 * Take ownership of another owner's slot.
 *
 * @param owner The owner to be disowned.
 */

    Owner(Owner&& owner) noexcept
    : mRecord{owner.mRecord}
    {
        owner.mRecord = nullptr;
    }

    Owner& operator =(Owner const&) = delete;

    ~Owner() noexcept {
        if (mRecord) {
            mRecord->target = nullptr;
            Registry::sRegistry.release(*mRecord);
        }
    }

/**
 * Occupy a registry slot with the given target pointer.
 *
 * @note This method must always be called with the same target pointer.
 * @return A reference to the owned registry slot.
 */

    SlotRef get(void* const target)
    {
        if (!mRecord) {
            mRecord = &Registry::sRegistry.take(target);
            Registry::sRegistry.retain(*mRecord);
        }
        assert(target == mRecord->target);
        return SlotRef{*mRecord};
    }

/**
 * Re-target the owned slot.
 *
 * @note Ignored when no slot is owned.
 * @param target The new target.
 */

    void retarget(void* const target)
    {
        if (mRecord) {
            mRecord->target = target;
        }
    }

private:
    Registry::Record* mRecord{nullptr};
};


/**
 * I provide a typed pointer for a pointer stored in the registry.
 *
 * My target changes when the slot is re-targetted and I become invalid
 * when it is cleared.
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
 * I hold an instance of Value.
 *
 * I can provide pointers which are invalidated when I have expired.
 */

template<typename Value>
class Target
{
public:
    struct forwardCtor {};

/**
 * Convenience function for invoking forwarding c'tor.
 */

    template<typename... Args>
    static constexpr Target create(Args&&... args)
    {
        return Target(forwardCtor{}, std::forward<Args>(args)...);
    }

/**
 * This constructor forwards its parameters to Value's c'tor, constructing
 * the instance in-place.
 */

    template<typename... Args>
    constexpr explicit Target(forwardCtor, Args&&... args)
    : mValue{std::forward<Args>(args)...}
    , mOwner{}
    {}

    Target(Target const& target) noexcept(std::is_nothrow_copy_constructible_v<Value>)
    : mValue{target.mValue}
    , mOwner{}
    {}

    Target(Target&& target) noexcept(std::is_nothrow_move_constructible_v<Value>)
    : mValue{std::forward<decltype(target.mValue)>(target.mValue)}
    , mOwner{std::move(target.mOwner)}
    {
        mOwner.retarget(&mValue);
    }

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
 * The pointer-like objects created by this method behave as follows:
 * 1) They refer to the value held by this Target instance.
 * 2) They expire (i.e. become equivalent to nullptr) when this Target
 *    instance is destroyed.
 * 3) When this Target instance appears as the source of a
 *    move-construction, all previously created pointers behave as if they
 *    were created by the newly constructed Target.
 *
 * @note New pointers created *after* this Target appeared as the source of
 * a move-construction will again refer to *this* instance.
 * @note This Target instance appearing as the source of a move-assignment
 * has no effect on any pointers.
 *
 * @return A volatile pointer to the Value of this object.
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
    std::cout << "vecRef=" << vecRef->name << '\n';

    std::cout << '\n' << R"(return 0;)" << '\n';
    return 0;
}
