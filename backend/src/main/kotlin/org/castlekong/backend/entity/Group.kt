package org.castlekong.backend.entity

import jakarta.persistence.*

@Entity
@Table(name = "groups")
data class Group(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,
    @Column(nullable = false, unique = true, length = 100)
    val name: String,
)

