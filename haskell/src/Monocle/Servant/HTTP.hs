{-# LANGUAGE DataKinds #-}

-- Generated by monocle-codegen. DO NOT EDIT!

-- |
-- Copyright: (c) 2021 Monocle authors
-- SPDX-License-Identifier: AGPL-3.0-only
module Monocle.Servant.HTTP (MonocleAPI, server) where

import Monocle.Api.Server (AuthenticatedUser, MagicJWTResponse, WhoAmIResponse, configGetAbout, configGetGroupMembers, configGetGroups, configGetProjects, configGetWorkspaces, crawlerAddDoc, crawlerCommit, crawlerCommitInfo, loginLoginValidation, magicJwt, metricGet, metricList, searchAuthor, searchCheck, searchFields, searchQuery, searchSuggestions, whoAmi)
import Monocle.Env
import Monocle.Protob.Config (GetAboutRequest, GetAboutResponse, GetGroupMembersRequest, GetGroupMembersResponse, GetGroupsRequest, GetGroupsResponse, GetProjectsRequest, GetProjectsResponse, GetWorkspacesRequest, GetWorkspacesResponse)
import Monocle.Protob.Crawler (AddDocRequest, AddDocResponse, CommitInfoRequest, CommitInfoResponse, CommitRequest, CommitResponse)
import Monocle.Protob.Login (LoginValidationRequest, LoginValidationResponse)
import Monocle.Protob.Metric (GetRequest, GetResponse, ListRequest, ListResponse)
import Monocle.Protob.Search (AuthorRequest, AuthorResponse, CheckRequest, CheckResponse, FieldsRequest, FieldsResponse, QueryRequest, QueryResponse, SuggestionsRequest, SuggestionsResponse)
import Monocle.Servant.PBJSON (PBJSON)
import Servant
import Servant.Auth.Server (Auth, Cookie, JWT)

type MonocleAPI =
  "login" :> "username" :> "validate" :> ReqBody '[JSON] Monocle.Protob.Login.LoginValidationRequest :> Post '[PBJSON, JSON] Monocle.Protob.Login.LoginValidationResponse
    :<|> "get_workspaces" :> ReqBody '[JSON] Monocle.Protob.Config.GetWorkspacesRequest :> Post '[PBJSON, JSON] Monocle.Protob.Config.GetWorkspacesResponse
    :<|> "get_projects" :> ReqBody '[JSON] Monocle.Protob.Config.GetProjectsRequest :> Post '[PBJSON, JSON] Monocle.Protob.Config.GetProjectsResponse
    :<|> "get_groups" :> ReqBody '[JSON] Monocle.Protob.Config.GetGroupsRequest :> Post '[PBJSON, JSON] Monocle.Protob.Config.GetGroupsResponse
    :<|> "get_group_members" :> ReqBody '[JSON] Monocle.Protob.Config.GetGroupMembersRequest :> Post '[PBJSON, JSON] Monocle.Protob.Config.GetGroupMembersResponse
    :<|> "about" :> ReqBody '[JSON] Monocle.Protob.Config.GetAboutRequest :> Post '[PBJSON, JSON] Monocle.Protob.Config.GetAboutResponse
    :<|> "suggestions" :> ReqBody '[JSON] Monocle.Protob.Search.SuggestionsRequest :> Post '[PBJSON, JSON] Monocle.Protob.Search.SuggestionsResponse
    :<|> "search" :> "fields" :> ReqBody '[JSON] Monocle.Protob.Search.FieldsRequest :> Post '[PBJSON, JSON] Monocle.Protob.Search.FieldsResponse
    :<|> "search" :> "check" :> ReqBody '[JSON] Monocle.Protob.Search.CheckRequest :> Post '[PBJSON, JSON] Monocle.Protob.Search.CheckResponse
    :<|> "search" :> "query" :> ReqBody '[JSON] Monocle.Protob.Search.QueryRequest :> Post '[PBJSON, JSON] Monocle.Protob.Search.QueryResponse
    :<|> "search" :> "author" :> ReqBody '[JSON] Monocle.Protob.Search.AuthorRequest :> Post '[PBJSON, JSON] Monocle.Protob.Search.AuthorResponse
    :<|> "metric" :> "list" :> ReqBody '[JSON] Monocle.Protob.Metric.ListRequest :> Post '[PBJSON, JSON] Monocle.Protob.Metric.ListResponse
    :<|> "metric" :> "get" :> ReqBody '[JSON] Monocle.Protob.Metric.GetRequest :> Post '[PBJSON, JSON] Monocle.Protob.Metric.GetResponse
    :<|> "crawler" :> "add" :> ReqBody '[JSON] Monocle.Protob.Crawler.AddDocRequest :> Post '[PBJSON, JSON] Monocle.Protob.Crawler.AddDocResponse
    :<|> "crawler" :> "commit" :> ReqBody '[JSON] Monocle.Protob.Crawler.CommitRequest :> Post '[PBJSON, JSON] Monocle.Protob.Crawler.CommitResponse
    :<|> "crawler" :> "get_commit_info" :> ReqBody '[JSON] Monocle.Protob.Crawler.CommitInfoRequest :> Post '[PBJSON, JSON] Monocle.Protob.Crawler.CommitInfoResponse
    :<|> Auth '[JWT, Cookie] AuthenticatedUser :> "whoami" :> Get '[JSON] WhoAmIResponse
    :<|> "magic_jwt" :> Get '[JSON] MagicJWTResponse

server :: ServerT MonocleAPI AppM
server =
  loginLoginValidation
    :<|> configGetWorkspaces
    :<|> configGetProjects
    :<|> configGetGroups
    :<|> configGetGroupMembers
    :<|> configGetAbout
    :<|> searchSuggestions
    :<|> searchFields
    :<|> searchCheck
    :<|> searchQuery
    :<|> searchAuthor
    :<|> metricList
    :<|> metricGet
    :<|> crawlerAddDoc
    :<|> crawlerCommit
    :<|> crawlerCommitInfo
    :<|> whoAmi
    :<|> magicJwt
