
#ifndef RANGE_HPP
#define RANGE_HPP

// range prototype
template<typename T>
class Range{
public:
	Range(
		bool inclStart,
		const T& start,
		const T& incr,
		const T& end,
		bool inclEnd
	):
		m_start(inclStart?start:start+incr),
		m_incr(incr),
		m_endidx((end-start)/incr-2 + inclStart + inclEnd),
		m_inf(false),
		m_idx(0)
	{}
	Range(
		bool inclStart,
		const T& start,
		const T& incr
	):
		m_start(inclStart?start:start+incr),
		m_incr(incr),
		m_endidx(0),
		m_inf(true),
		m_idx(0)
	{}
	Range(const Range<T>& other):
		m_start(other.m_start),
		m_incr(other.m_incr),
		m_endidx(other.m_endidx),
		m_inf(other.m_inf),
		m_idx(0)
	{}
	Range& operator=(const Range<T>& other){
		if (this != &other){
			m_start = other.m_start;
			m_incr = other.m_incr;
			m_endidx = other.m_endidx;
			m_inf = other.m_inf;
			m_idx = 0;
		}
		return *this;
	}

	const T front(){
		return m_start + m_incr*m_idx;
	}
	void popFront(){
		m_idx++;
	}
	bool empty(){
		if(m_inf){return false;}
		return m_idx > m_endidx;
	}
	Range save(){
		return Range(m_start, m_incr, m_endidx, m_inf, m_idx);
	}

private:
	Range(const T& start, const T& incr, const size_t& endidx, bool inf, const size_t& idx):
		m_start(start),
		m_incr(incr),
		m_endidx(endidx),
		m_inf(inf),
		m_idx(idx)
	{}

	T m_start;
	T m_incr;
	size_t m_endidx;
	bool m_inf;
	size_t m_idx;
};

#endif
