CREATE TABLE `access_term_associations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `describable_id` int(11) DEFAULT NULL,
  `describable_type` varchar(255) DEFAULT NULL,
  `access_term_id` int(11) DEFAULT NULL,
  `role` varchar(255) DEFAULT NULL,
  `controlaccess` tinyint(1) DEFAULT '0',
  `name_subject` tinyint(1) DEFAULT '0',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `function` varchar(255) DEFAULT NULL,
  `questionable` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `index_access_term_associations_on_describable_id` (`describable_id`),
  KEY `index_access_term_associations_on_describable_type` (`describable_type`)
) ENGINE=InnoDB AUTO_INCREMENT=356059 DEFAULT CHARSET=utf8;

CREATE TABLE `access_terms` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `term_original` varchar(255) DEFAULT NULL,
  `term_authorized` varchar(255) DEFAULT NULL,
  `term_type` varchar(255) DEFAULT NULL,
  `authority` varchar(255) DEFAULT NULL,
  `authority_record_id` varchar(255) DEFAULT NULL,
  `value_uri` varchar(255) DEFAULT NULL,
  `control_source` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_access_terms_on_term_original` (`term_original`),
  KEY `index_access_terms_on_term_authorized` (`term_authorized`),
  KEY `index_access_terms_on_value_uri` (`value_uri`)
) ENGINE=InnoDB AUTO_INCREMENT=156624 DEFAULT CHARSET=utf8;

CREATE TABLE `amat_records` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `collection_id` int(11) DEFAULT NULL,
  `node_id` int(11) DEFAULT NULL,
  `mss_id` int(11) DEFAULT NULL,
  `pdf_filename` varchar(255) DEFAULT NULL,
  `pdf_url` varchar(255) DEFAULT NULL,
  `ead_filename` varchar(255) DEFAULT NULL,
  `ead_url` varchar(255) DEFAULT NULL,
  `ead_ingest_error` tinyint(1) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `verified` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=6810 DEFAULT CHARSET=utf8;

CREATE TABLE `catalog_imports` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `bnumber` varchar(255) DEFAULT NULL,
  `collection_id` int(11) DEFAULT NULL,
  `catalog_record_updated` date DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=23460 DEFAULT CHARSET=utf8;

CREATE TABLE `collection_associations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `describable_id` int(11) DEFAULT NULL,
  `describable_type` varchar(255) DEFAULT NULL,
  `collection_id` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_collection_associations_on_describable_id` (`describable_id`),
  KEY `index_collection_associations_on_describable_type` (`describable_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `collection_responses` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `collection_id` int(11) DEFAULT NULL,
  `desc_data` longtext,
  `structure` longtext,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `digital_objects` longtext,
  PRIMARY KEY (`id`),
  KEY `index_collection_responses_on_collection_id` (`collection_id`)
) ENGINE=InnoDB AUTO_INCREMENT=9283 DEFAULT CHARSET=utf8;

CREATE TABLE `collections` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `origination` varchar(255) DEFAULT NULL,
  `org_unit_id` int(11) DEFAULT NULL,
  `date_statement` varchar(255) DEFAULT NULL,
  `extent_statement` varchar(255) DEFAULT NULL,
  `linear_feet` float DEFAULT NULL,
  `keydate` int(11) DEFAULT NULL,
  `identifier_value` varchar(255) DEFAULT NULL,
  `identifier_type` varchar(255) DEFAULT NULL,
  `bnumber` varchar(255) DEFAULT NULL,
  `call_number` varchar(255) DEFAULT NULL,
  `pdf_finding_aid` varchar(255) DEFAULT NULL,
  `max_depth` int(11) DEFAULT NULL,
  `series_count` int(11) DEFAULT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `boost_queries` longtext,
  `date_processed` int(11) DEFAULT NULL,
  `component_layout_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_collections_on_title` (`title`),
  KEY `index_collections_on_identifier_value` (`identifier_value`),
  KEY `index_collections_on_identifier_type` (`identifier_type`),
  KEY `index_collections_on_org_unit_id` (`org_unit_id`),
  KEY `index_collections_on_bnumber` (`bnumber`),
  KEY `index_collections_on_keydate` (`keydate`)
) ENGINE=InnoDB AUTO_INCREMENT=9142 DEFAULT CHARSET=utf8;

CREATE TABLE `component_layouts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `description` text,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;

CREATE TABLE `component_responses` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `component_id` int(11) DEFAULT NULL,
  `desc_data` longtext,
  `structure` longtext,
  `digital_objects` longtext,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_component_responses_on_component_id` (`component_id`)
) ENGINE=InnoDB AUTO_INCREMENT=783193 DEFAULT CHARSET=utf8;

CREATE TABLE `components` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `origination` varchar(255) DEFAULT NULL,
  `identifier_value` varchar(255) DEFAULT NULL,
  `identifier_type` varchar(255) DEFAULT NULL,
  `collection_id` int(11) DEFAULT NULL,
  `parent_id` int(11) DEFAULT NULL,
  `sib_seq` int(11) DEFAULT NULL,
  `has_children` tinyint(1) DEFAULT '0',
  `level_num` int(11) DEFAULT NULL,
  `level_text` varchar(255) DEFAULT NULL,
  `top_component_id` int(11) DEFAULT NULL,
  `max_depth` int(11) DEFAULT NULL,
  `org_unit_id` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `resource_type` varchar(255) DEFAULT NULL,
  `date_statement` varchar(255) DEFAULT NULL,
  `extent_statement` varchar(255) DEFAULT NULL,
  `linear_feet` float DEFAULT NULL,
  `load_seq` int(11) DEFAULT NULL,
  `boost_queries` longtext,
  PRIMARY KEY (`id`),
  KEY `index_components_on_title` (`title`),
  KEY `index_components_on_identifier_value` (`identifier_value`),
  KEY `index_components_on_identifier_type` (`identifier_type`),
  KEY `index_components_on_org_unit_id` (`org_unit_id`),
  KEY `index_components_on_collection_id` (`collection_id`),
  KEY `index_components_on_parent_id` (`parent_id`),
  KEY `index_components_on_top_component_id` (`top_component_id`),
  KEY `collection_load_seq` (`collection_id`,`load_seq`)
) ENGINE=InnoDB AUTO_INCREMENT=787088 DEFAULT CHARSET=utf8;

CREATE TABLE `delayed_jobs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `priority` int(11) NOT NULL DEFAULT '0',
  `attempts` int(11) NOT NULL DEFAULT '0',
  `handler` text NOT NULL,
  `last_error` text,
  `run_at` datetime DEFAULT NULL,
  `locked_at` datetime DEFAULT NULL,
  `failed_at` datetime DEFAULT NULL,
  `locked_by` varchar(255) DEFAULT NULL,
  `queue` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `delayed_jobs_priority` (`priority`,`run_at`)
) ENGINE=InnoDB AUTO_INCREMENT=255 DEFAULT CHARSET=utf8;

CREATE TABLE `descriptions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `describable_id` int(11) DEFAULT NULL,
  `describable_type` varchar(255) DEFAULT NULL,
  `data` longtext,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_descriptions_on_describable_id` (`describable_id`),
  KEY `index_descriptions_on_describable_type` (`describable_type`)
) ENGINE=InnoDB AUTO_INCREMENT=790565 DEFAULT CHARSET=utf8;

CREATE TABLE `documents` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `describable_type` varchar(255) DEFAULT NULL,
  `describable_id` int(11) DEFAULT NULL,
  `document_type` varchar(255) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `file` varchar(255) DEFAULT NULL,
  `index_only` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=127 DEFAULT CHARSET=utf8;

CREATE TABLE `ead_ingests` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `collection_id` int(11) DEFAULT NULL,
  `update_type` varchar(255) DEFAULT NULL,
  `filename` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3075 DEFAULT CHARSET=utf8;

CREATE TABLE `external_resources` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `describable_type` varchar(255) DEFAULT NULL,
  `describable_id` int(11) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `resource_type` varchar(255) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8;

CREATE TABLE `guide_guide_associations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `parent_guide_id` int(11) DEFAULT NULL,
  `child_guide_id` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

CREATE TABLE `guides` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `description` text,
  `url_token` varchar(255) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;

CREATE TABLE `mods_exports` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `nypl_repo_objects` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `describable_id` int(11) DEFAULT NULL,
  `describable_type` varchar(255) DEFAULT NULL,
  `uuid` varchar(255) DEFAULT NULL,
  `resource_type` varchar(255) DEFAULT NULL,
  `total_captures` int(11) DEFAULT NULL,
  `capture_ids` longtext,
  `sib_seq` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_nypl_repo_objects_on_describable_id` (`describable_id`),
  KEY `index_nypl_repo_objects_on_describable_type` (`describable_type`)
) ENGINE=InnoDB AUTO_INCREMENT=15210 DEFAULT CHARSET=utf8;

CREATE TABLE `org_units` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `name_short` varchar(255) DEFAULT NULL,
  `code` varchar(255) DEFAULT NULL,
  `sib_seq` int(11) DEFAULT NULL,
  `marc_org_code` varchar(255) DEFAULT NULL,
  `center` varchar(255) DEFAULT NULL,
  `location` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `standard_access_note` text,
  `url` varchar(255) DEFAULT NULL,
  `description` text,
  `collection_count` int(11) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `access_rules` text,
  `email_response_text` text,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8;

CREATE TABLE `place_name_associations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `place_id` int(11) DEFAULT NULL,
  `name_association_id` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `questionable` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6448 DEFAULT CHARSET=utf8;

CREATE TABLE `record_guide_associations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `description` text,
  `describable_type` varchar(255) DEFAULT NULL,
  `describable_id` int(11) DEFAULT NULL,
  `guide_id` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

CREATE TABLE `schema_migrations` (
  `version` varchar(255) NOT NULL,
  UNIQUE KEY `unique_schema_migrations` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `search_indices` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `index_type` varchar(255) DEFAULT NULL,
  `adds` int(11) DEFAULT NULL,
  `updates` int(11) DEFAULT NULL,
  `deletes` int(11) DEFAULT NULL,
  `processing_errors` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `index_scope` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=59 DEFAULT CHARSET=utf8;

CREATE TABLE `user_org_unit_associations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `org_unit_id` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `email` varchar(255) NOT NULL DEFAULT '',
  `encrypted_password` varchar(255) NOT NULL DEFAULT '',
  `reset_password_token` varchar(255) DEFAULT NULL,
  `reset_password_sent_at` datetime DEFAULT NULL,
  `remember_created_at` datetime DEFAULT NULL,
  `sign_in_count` int(11) DEFAULT '0',
  `current_sign_in_at` datetime DEFAULT NULL,
  `last_sign_in_at` datetime DEFAULT NULL,
  `current_sign_in_ip` varchar(255) DEFAULT NULL,
  `last_sign_in_ip` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `username` varchar(255) DEFAULT NULL,
  `role` varchar(255) DEFAULT NULL,
  `name_first` varchar(255) DEFAULT NULL,
  `name_last` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_users_on_email` (`email`),
  UNIQUE KEY `index_users_on_reset_password_token` (`reset_password_token`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

INSERT INTO schema_migrations (version) VALUES ('20120607201017');

INSERT INTO schema_migrations (version) VALUES ('20120608181301');

INSERT INTO schema_migrations (version) VALUES ('20120608182450');

INSERT INTO schema_migrations (version) VALUES ('20120608185917');

INSERT INTO schema_migrations (version) VALUES ('20120815184019');

INSERT INTO schema_migrations (version) VALUES ('20120815190029');

INSERT INTO schema_migrations (version) VALUES ('20120815200902');

INSERT INTO schema_migrations (version) VALUES ('20120815212518');

INSERT INTO schema_migrations (version) VALUES ('20120912152112');

INSERT INTO schema_migrations (version) VALUES ('20121208033825');

INSERT INTO schema_migrations (version) VALUES ('20130304200008');

INSERT INTO schema_migrations (version) VALUES ('20130329213709');

INSERT INTO schema_migrations (version) VALUES ('20130409215218');

INSERT INTO schema_migrations (version) VALUES ('20130411190648');

INSERT INTO schema_migrations (version) VALUES ('20130415203655');

INSERT INTO schema_migrations (version) VALUES ('20130417145636');

INSERT INTO schema_migrations (version) VALUES ('20130418164114');

INSERT INTO schema_migrations (version) VALUES ('20130430140846');

INSERT INTO schema_migrations (version) VALUES ('20130502212303');

INSERT INTO schema_migrations (version) VALUES ('20130503192512');

INSERT INTO schema_migrations (version) VALUES ('20130506154645');

INSERT INTO schema_migrations (version) VALUES ('20130507164530');

INSERT INTO schema_migrations (version) VALUES ('20130515201609');

INSERT INTO schema_migrations (version) VALUES ('20130515205107');

INSERT INTO schema_migrations (version) VALUES ('20130521174049');

INSERT INTO schema_migrations (version) VALUES ('20130522210332');

INSERT INTO schema_migrations (version) VALUES ('20130528170736');

INSERT INTO schema_migrations (version) VALUES ('20130611184254');

INSERT INTO schema_migrations (version) VALUES ('20130613173252');

INSERT INTO schema_migrations (version) VALUES ('20130624161822');

INSERT INTO schema_migrations (version) VALUES ('20130702220934');

INSERT INTO schema_migrations (version) VALUES ('20130715190150');

INSERT INTO schema_migrations (version) VALUES ('20130718211905');

INSERT INTO schema_migrations (version) VALUES ('20130722220304');

INSERT INTO schema_migrations (version) VALUES ('20130723212659');

INSERT INTO schema_migrations (version) VALUES ('20130803204535');

INSERT INTO schema_migrations (version) VALUES ('20130824032548');

INSERT INTO schema_migrations (version) VALUES ('20130910144643');

INSERT INTO schema_migrations (version) VALUES ('20130918145550');

INSERT INTO schema_migrations (version) VALUES ('20131017015710');

INSERT INTO schema_migrations (version) VALUES ('20131022165514');

INSERT INTO schema_migrations (version) VALUES ('20131104181727');

INSERT INTO schema_migrations (version) VALUES ('20131105203616');

INSERT INTO schema_migrations (version) VALUES ('20131108171801');

INSERT INTO schema_migrations (version) VALUES ('20131108191352');

INSERT INTO schema_migrations (version) VALUES ('20131112155538');

INSERT INTO schema_migrations (version) VALUES ('20131113163226');

INSERT INTO schema_migrations (version) VALUES ('20131118215241');

INSERT INTO schema_migrations (version) VALUES ('20131126185608');

INSERT INTO schema_migrations (version) VALUES ('20131126195733');

INSERT INTO schema_migrations (version) VALUES ('20131126200632');

INSERT INTO schema_migrations (version) VALUES ('20131126200725');

INSERT INTO schema_migrations (version) VALUES ('20131129150756');