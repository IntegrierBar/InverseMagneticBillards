/*
Simple structs for double preccision 2d vectors and matricies
*/


#ifndef VECTOR_D_H
#define VECTOR_D_H

#include <Vector2.hpp>
#include <cmath>
#include <string>

# define M_PI           3.14159265358979323846

namespace godot {

	struct vec2_d {
		//--------------------------
		double x, y;

		double& operator[](int j) { return *(&x + j); }
		double operator[](int j) const { return *(&x + j); }
		vec2_d(double x0 = 0, double y0 = 0) { x = x0; y = y0; }
		vec2_d(Vector2 v) { x = v.x; y = v.y; }
		vec2_d operator*(double a) const { return vec2_d(x * a, y * a); }
		vec2_d operator/(double a) const { return vec2_d(x / a, y / a); }
		vec2_d operator+(const vec2_d& v) const { return vec2_d(x + v.x, y + v.y); }
		vec2_d operator-(const vec2_d& v) const { return vec2_d(x - v.x, y - v.y); }
		vec2_d operator*(const vec2_d& v) const { return vec2_d(x * v.x, y * v.y); }
		vec2_d operator-() const { return vec2_d(-x, -y); }
		Vector2 to_godot() const { return Vector2(x, y); }
		Vector2 to_draw() const { return Vector2(x, -y); }
		inline double angle() const {
			double angle = std::atan2(y, x);
			if (angle < 0) return angle + 2 * M_PI; // make sure angle is always positive!
			return angle;
		}
		String to_string() const {
			String s = std::to_string(x).c_str();	// there should be a more elegant way of doing this, but I dont know it
			s += " ";
			s += std::to_string(y).c_str();
			return s;
		}
	};

	inline vec2_d round(const vec2_d& v) {
		return vec2_d(floor(v.x + 0.5), floor(v.y + 0.5));
	}

	inline double dot(const vec2_d& v1, const vec2_d& v2) {
		return (v1.x * v2.x + v1.y * v2.y);
	}

	inline double det(const vec2_d& v1, const vec2_d& v2) {
		return (v1.x * v2.y - v1.y * v2.x);
	}

	inline double length(const vec2_d& v) { return sqrt(dot(v, v)); }
	inline double length_squared(const vec2_d& v) { return dot(v, v); }
	inline double angle_between(const vec2_d& v1, const vec2_d& v2) {
		return std::atan2(det(v1, v2), dot(v1, v2));
	}

	inline vec2_d normalize(const vec2_d& v) { return v * (1 / length(v)); }

	inline vec2_d operator*(double a, const vec2_d& v) { return vec2_d(v.x * a, v.y * a); }

	inline vec2_d project(const vec2_d& pos, const vec2_d& p, const vec2_d& dir) {
		vec2_d d = normalize(dir);
		return dot(pos - p, d) * d + p;
	}


	//---------------------------
	struct mat2_d { // row-major matrix 2x2 for doubles
		//---------------------------
		vec2_d rows[2];

	public:
		mat2_d() {}
		mat2_d(double m00, double m01,
			double m10, double m11) {
			rows[0][0] = m00; rows[0][1] = m01;
			rows[1][0] = m10; rows[1][1] = m11;
		}
		mat2_d(vec2_d row0, vec2_d row1) {
			rows[0] = row0; rows[1] = row1;
		}
		vec2_d& operator[](int i) { return rows[i]; }
		vec2_d operator[](int i) const { return rows[i]; }
		operator float* () const { return (float*)this; }
	};

	//inline vec2_d operator*(const vec2_d& v, const mat2_d& mat) {
	//	return v[0] * mat[0] + v[1] * mat[1];
	//}

	inline vec2_d operator*(const mat2_d& mat, const vec2_d& v) {
		return vec2_d(dot(mat[0], v), dot(mat[1], v));
	}

	//inline mat2_d operator*(const mat2_d& left, const mat2_d& right) {
	//	mat2_d result;
	//	for (int i = 0; i < 2; i++) result.rows[i] = left.rows[i] * right;
	//	return result;
	//}

}

#endif // VECTOR_D_H