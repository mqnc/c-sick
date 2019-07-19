#ifndef POINTERS__HPP
#define POINTERS__HPP

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
            void* stackbox;
            Record* nextRecord;
        };
    };

/**
 * The single global instance of the registry.
 */

    static Registry sRegistry;

/**
 * Get a record pointing to the given stackbox from the registry.
 *
 * @param stackbox The stackbox to store in the slot.
 * @return A record whose reference count is zero that refers to the given
 * point.
 */

    Record& take(void* stackbox)
    {
        if (!mFreeRecord) {
            mRecords.resize(1 + mRecords.size());
            mFreeRecord = &mRecords.back();
        }
        Record& res{*mFreeRecord};
        mFreeRecord = res.nextRecord;
        assert(0 == res.count);
        res.stackbox = stackbox;
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
 * when given a stackbox pointer. I provide counted references to that slot
 * that remain valid even after I have expired and cleared the stored
 * stackbox pointer.
 */

class SlotRef::Owner
{
public:
    Owner() = default;
    Owner(Owner const&) = delete;
    Owner& operator =(Owner const&) = delete;

    ~Owner() noexcept {
        if (mRecord) {
            mRecord->stackbox = nullptr;
            Registry::sRegistry.release(*mRecord);
        }
    }

/**
 * Occupy a registry slot with the given stackbox pointer.
 *
 * @note This method must always be called with the same stackbox pointer.
 * @return A reference to the owned registry slot.
 */

    SlotRef get(void* const stackbox)
    {
        if (!mRecord) {
            mRecord = &Registry::sRegistry.take(stackbox);
            Registry::sRegistry.retain(*mRecord);
        }
        assert(stackbox == mRecord->stackbox);
        return SlotRef{*mRecord};
    }

private:
    Registry::Record* mRecord{nullptr};
};


/**
 * I provide a typed pointer for a pointer stored in the registry.
 *
 * I become invalid when that entity expires.
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
        return static_cast<Value*>(mSlotRef->stackbox);
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
class Stackbox
{
public:
    struct forwardCtor {};

/**
 * Convenience function for invoking forwarding c'tor.
 */

    template<typename... Args>
    static constexpr Stackbox create(Args&&... args)
    {
        return Stackbox(forwardCtor{}, std::forward<Args>(args)...);
    }

/**
 * This constructor forwards its parameters to Value's c'tor, constructing
 * the instance in-place.
 */

    template<typename... Args>
    constexpr explicit Stackbox(forwardCtor, Args&&... args)
    : mValue{std::forward<Args>(args)...}
    , mOwner{}
    {}

    Stackbox(Stackbox const& stackbox) noexcept(std::is_nothrow_copy_constructible_v<Value>)
    : mValue{stackbox.mValue}
    , mOwner{}
    {}

    Stackbox(Stackbox&& stackbox) noexcept(std::is_nothrow_move_constructible_v<Value>)
    : mValue{std::forward<decltype(stackbox.mValue)>(stackbox.mValue)}
    , mOwner{}
    {}

    Stackbox& operator =(Stackbox const& stackbox) noexcept(std::is_nothrow_copy_assignable_v<Value>)
    {
        mValue = stackbox.mValue;
        // Omit mOwner since it's a reference to ourselves.
        return *this;
    }

    Stackbox& operator =(Stackbox&& stackbox) noexcept(std::is_nothrow_move_assignable_v<Value>)
    {
        mValue = std::forward<decltype(stackbox.mValue)>(stackbox.mValue);
        // Omit mOwner since it's a reference to ourselves.
        return *this;
    }

    template<typename U>
    Stackbox& operator =(Stackbox<U> const& stackbox)
    {
        mValue = stackbox.mValue;
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
 * @return A volatile pointer to the Value of this object which expires
 * when it is destroyed.
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
 * a wrapper for stackbox construction that has similar syntax to std::make_unique and std::make_shared
 */
template<typename T, typename... Args>
Stackbox<T> make_stackbox(Args&&... args)
{
	return Stackbox<T> (typename Stackbox<T>::forwardCtor{}, std::forward<Args>(args)...);
}

#ifdef notdef
/**
 * @return A volatile pointer to a local variable.
 */
VolatilePtr<Noisy> foo()
{
    std::cout << '\n' << R"(auto stack{Stackbox<Noisy>::create("Stackbert")};)" << '\n';
    auto stack{Stackbox<Noisy>::create("Stackbert")};

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

    std::cout << '\n' << R"(std::vector<Stackbox<Noisy>> noisies{"Vectorbert"};)" << '\n';
    std::vector<Stackbox<Noisy>> noisies{};
    noisies.emplace_back(Stackbox<Noisy>::forwardCtor{}, "Vectorbert");

    std::cout << '\n' << R"(auto vecRef{noisies.front().ptr()};)" << '\n';
    auto vecRef{noisies.front().ptr()};
    std::cout << "vecRef=" << vecRef->name << '\n';

    std::cout << '\n' << R"(for (int i{0}; i != 4; ++i) {)" << '\n';
    for (int i{0}; i != 4; ++i) {
        noisies.emplace_back(Stackbox<Noisy>::forwardCtor{}, "goodbye");
    }
    std::cout << "vecRef=" << vecRef.get() << '\n';

    std::cout << '\n' << R"(return 0;)" << '\n';
    return 0;
}
#endif
#endif
